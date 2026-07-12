#!/usr/bin/env bash
# ==========================================================================
# IJRI — admin + submissions + approval flow.
#   - register -> /pending (awaiting admin approval)
#   - /admin (staff): approve users, add/remove sections, see submissions
#   - /submit (approved authors): submit a manuscript
# Run in repo:  bash build-admin.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Admin + submissions + approval flow..."
mkdir -p src/lib src/app/admin src/app/submit src/app/pending src/app/register \
         src/app/api/admin/users src/app/api/admin/sections src/app/api/submissions

# ---------------------------------------------------------------- account helper (DB-fresh, incl. approved)
cat > src/lib/account.ts << 'IJRI_EOF'
import { prisma } from "./prisma";
import { getCurrentUser } from "./auth";

export async function getAccount(req?: Request) {
  const u = await getCurrentUser(req);
  if (!u) return null;
  return prisma.user.findUnique({
    where: { id: u.id },
    select: { id: true, name: true, email: true, role: true, approved: true },
  });
}
IJRI_EOF

# ---------------------------------------------------------------- admin: users API
cat > src/app/api/admin/users/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const users = await prisma.user.findMany({
    orderBy: { createdAt: "desc" },
    select: { id: true, name: true, email: true, role: true, approved: true, affiliation: true, createdAt: true },
  });
  return Response.json(users);
}

export async function PATCH(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return forbidden("Only an administrator can change access");
  const body = await req.json().catch(() => null);
  const userId = String(body?.userId ?? "");
  if (!userId) return Response.json({ error: "Missing userId" }, { status: 400 });

  const data: { approved?: boolean; role?: "AUTHOR" | "EDITOR" } = {};
  if (typeof body?.approved === "boolean") data.approved = body.approved;
  if (body?.role === "AUTHOR" || body?.role === "EDITOR") data.role = body.role;

  const updated = await prisma.user.update({
    where: { id: userId }, data,
    select: { id: true, approved: true, role: true },
  });
  return Response.json(updated);
}
IJRI_EOF

# ---------------------------------------------------------------- admin: sections API
cat > src/app/api/admin/sections/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

const slugify = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const sections = await prisma.section.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { articles: true } } },
  });
  return Response.json(sections);
}

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN") return forbidden("Only an administrator can add sections");
  const body = await req.json().catch(() => null);
  const name = String(body?.name ?? "").trim();
  if (!name) return Response.json({ error: "Section name required" }, { status: 400 });
  const slug = slugify(name);
  const existing = await prisma.section.findFirst({ where: { OR: [{ name }, { slug }] } });
  if (existing) return Response.json({ error: "Section already exists" }, { status: 409 });
  const section = await prisma.section.create({ data: { name, slug } });
  return Response.json(section, { status: 201 });
}

export async function DELETE(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN") return forbidden("Only an administrator can remove sections");
  const body = await req.json().catch(() => null);
  const id = String(body?.id ?? "");
  if (!id) return Response.json({ error: "Missing id" }, { status: 400 });
  const count = await prisma.article.count({ where: { sectionId: id } });
  if (count > 0) return Response.json({ error: `Cannot delete: ${count} article(s) use this section` }, { status: 409 });
  await prisma.section.delete({ where: { id } });
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- submissions API (approval-gated POST)
cat > src/app/api/submissions/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!acc.approved && !isStaff(acc.role)) return forbidden("Your account is awaiting approval");

  const b = await req.json().catch(() => null);
  const { title, abstract, bodyHtml, authorNames, affiliation, sectionId } = b ?? {};
  if (!title || !abstract || !bodyHtml || !sectionId)
    return Response.json({ error: "Missing required fields" }, { status: 400 });

  const article = await prisma.article.create({
    data: {
      title, abstract, bodyHtml,
      authorNames: authorNames ?? acc.name, affiliation, sectionId,
      status: "SUBMITTED", submittedById: acc.id,
    },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  return Response.json(queue);
}
IJRI_EOF

# ---------------------------------------------------------------- pending page
cat > src/app/pending/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconShield } from "@/lib/icons";

export const dynamic = "force-dynamic";

export default async function Pending() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const ready = acc.approved || isStaff(acc.role);

  return (
    <main style={{ maxWidth: 620, margin: "60px auto", padding: "0 20px", textAlign: "center" }}>
      <div style={{ display: "inline-flex", color: T.ink }}><IconShield size={40} stroke={1.2} /></div>
      <div style={{ marginTop: 14 }}><Eyebrow inverse>{ready ? "Account active" : "Awaiting approval"}</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "14px 0 10px" }}>
        {ready ? `Welcome, ${acc.name}` : "Thanks for registering"}
      </h1>
      {ready ? (
        <>
          <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>
            Your account is active. You can now submit manuscripts and access member features.
          </p>
          <div style={{ marginTop: 20, display: "flex", gap: 12, justifyContent: "center" }}>
            <Link href="/submit" style={{ padding: "11px 18px", background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase" }}>Submit a manuscript</Link>
            {isStaff(acc.role) && <Link href="/admin" style={{ padding: "11px 18px", border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase" }}>Admin</Link>}
          </div>
        </>
      ) : (
        <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>
          Your account has been created and is <strong>awaiting approval</strong> by the editorial office. Contributor access — including manuscript submission — is enabled once an administrator approves your account. You&rsquo;ll be able to submit as soon as that&rsquo;s done.
        </p>
      )}
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 26 }}>
        <Link href="/" style={{ textDecoration: "underline" }}>Return to the journal</Link>
      </p>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- register -> pending
cat > src/app/register/page.tsx << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { T } from "@/lib/ui";

export default function Register() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [affiliation, setAffiliation] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const res = await fetch("/api/auth/register", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, affiliation, password }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      setLoading(false); setErr(data.error ?? "Could not create account."); return;
    }
    await signIn("credentials", { email, password, redirect: false });
    setLoading(false);
    router.push("/pending"); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "11px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };
  const lbl: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted };

  return (
    <main style={{ maxWidth: 380, margin: "60px auto", padding: "0 20px" }}>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "0 0 6px" }}>Create account</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 22px" }}>Register to contribute. Access is enabled after approval by the editorial office.</p>
      <form onSubmit={submit}>
        <label style={lbl}>Full name<input style={input} value={name} onChange={(e) => setName(e.target.value)} required /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Email<input style={input} type="email" value={email} onChange={(e) => setEmail(e.target.value)} required /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Affiliation (optional)<input style={input} value={affiliation} onChange={(e) => setAffiliation(e.target.value)} /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Password<input style={input} type="password" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={8} /></label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ width: "100%", marginTop: 20, padding: "12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Creating…" : "Create account"}
        </button>
      </form>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 20 }}>
        Already have an account? <Link href="/login" style={{ textDecoration: "underline", color: T.ink }}>Sign in</Link>
      </p>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- admin page (gate) + panel
cat > src/app/admin/page.tsx << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import AdminPanel from "./AdminPanel";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");
  return <AdminPanel me={{ name: acc.name, role: acc.role }} />;
}
IJRI_EOF

cat > src/app/admin/AdminPanel.tsx << 'IJRI_EOF'
"use client";
import { useEffect, useState } from "react";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers, IconLayers, IconDoc } from "@/lib/icons";

type U = { id: string; name: string; email: string; role: string; approved: boolean; affiliation?: string | null };
type S = { id: string; name: string; slug: string; _count: { articles: number } };
type Q = { id: string; title: string; status: string; section: { name: string }; submittedBy: { name: string }; reviews: { id: string }[] };

const canAdmin = (role: string) => role === "ADMIN" || role === "CHIEF_EDITOR";

export default function AdminPanel({ me }: { me: { name: string; role: string } }) {
  const [users, setUsers] = useState<U[]>([]);
  const [sections, setSections] = useState<S[]>([]);
  const [queue, setQueue] = useState<Q[]>([]);
  const [newSection, setNewSection] = useState("");
  const [msg, setMsg] = useState("");

  async function load() {
    const [u, s, q] = await Promise.all([
      fetch("/api/admin/users").then((r) => r.json()),
      fetch("/api/admin/sections").then((r) => r.json()),
      fetch("/api/submissions").then((r) => r.json()),
    ]);
    setUsers(Array.isArray(u) ? u : []);
    setSections(Array.isArray(s) ? s : []);
    setQueue(Array.isArray(q) ? q : []);
  }
  useEffect(() => { load(); }, []);

  async function setApproved(id: string, approved: boolean) {
    await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId: id, approved }) });
    load();
  }
  async function setRole(id: string, role: string) {
    await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId: id, role }) });
    load();
  }
  async function addSection() {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: newSection }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not add section"); return; }
    setNewSection(""); load();
  }
  async function delSection(id: string) {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not delete section"); return; }
    load();
  }

  const H = ({ icon, children }: { icon: React.ReactNode; children: React.ReactNode }) => (
    <div style={{ display: "flex", alignItems: "center", gap: 9, margin: "34px 0 4px", color: T.ink }}>
      {icon}<h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", margin: 0, borderBottom: `2px solid ${T.ink}`, paddingBottom: 6, flex: 1 }}>{children}</h2>
    </div>
  );
  const btn = (bg: string, color: string): React.CSSProperties => ({ background: bg, color, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.04em", textTransform: "uppercase", padding: "5px 10px", cursor: "pointer" });

  return (
    <main style={{ maxWidth: 980, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Admin</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 4px" }}>Editorial administration</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>Signed in as {me.name} · {me.role}</p>
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}

      <H icon={<IconUsers size={18} />}>Users &amp; access</H>
      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontFamily: T.sans, fontSize: 13 }}>
          <thead><tr style={{ textAlign: "left", color: T.muted, fontSize: 11, textTransform: "uppercase", letterSpacing: "0.06em" }}>
            <th style={{ padding: "8px 6px" }}>Name</th><th>Email</th><th>Role</th><th>Status</th><th></th>
          </tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} style={{ borderTop: `1px solid ${T.rule}` }}>
                <td style={{ padding: "9px 6px" }}>{u.name}</td>
                <td style={{ color: T.muted }}>{u.email}</td>
                <td>{u.role}</td>
                <td style={{ color: u.approved ? "#1a7f37" : "#b26a00" }}>{u.approved ? "Approved" : "Pending"}</td>
                <td style={{ display: "flex", gap: 6, padding: "7px 0", flexWrap: "wrap" }}>
                  {canAdmin(me.role) && (u.approved
                    ? <button style={btn(T.paper, T.ink)} onClick={() => setApproved(u.id, false)}>Revoke</button>
                    : <button style={btn(T.ink, T.paper)} onClick={() => setApproved(u.id, true)}>Approve</button>)}
                  {canAdmin(me.role) && u.role === "AUTHOR" && <button style={btn(T.paper, T.ink)} onClick={() => setRole(u.id, "EDITOR")}>Make editor</button>}
                  {canAdmin(me.role) && u.role === "EDITOR" && <button style={btn(T.paper, T.ink)} onClick={() => setRole(u.id, "AUTHOR")}>Make author</button>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <H icon={<IconLayers size={18} />}>Sections</H>
      <div style={{ display: "flex", gap: 8, margin: "6px 0 14px" }}>
        <input value={newSection} onChange={(e) => setNewSection(e.target.value)} placeholder="New section name" style={{ flex: 1, maxWidth: 320, fontFamily: T.sans, fontSize: 14, padding: "8px 10px", border: `1px solid ${T.ink}` }} />
        <button style={btn(T.ink, T.paper)} onClick={addSection}>Add</button>
      </div>
      <div style={{ borderTop: `1px solid ${T.rule}` }}>
        {sections.map((s) => (
          <div key={s.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 4px", borderBottom: `1px solid ${T.rule}`, fontFamily: T.sans, fontSize: 14 }}>
            <span>{s.name} <span style={{ color: T.muted, fontSize: 12 }}>· {s._count.articles} article(s)</span></span>
            {me.role === "ADMIN" && <button style={btn(T.paper, T.ink)} onClick={() => delSection(s.id)} disabled={s._count.articles > 0}>Remove</button>}
          </div>
        ))}
      </div>

      <H icon={<IconDoc size={18} />}>Submission queue</H>
      {queue.length === 0 ? (
        <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted }}>No submissions awaiting review.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.rule}` }}>
          {queue.map((q) => (
            <div key={q.id} style={{ padding: "12px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ fontFamily: T.serif, fontSize: 17 }}>{q.title}</div>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{q.section.name} · by {q.submittedBy.name} · {q.status} · {q.reviews.length} review(s)</div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- submit page (gate) + form
cat > src/app/submit/page.tsx << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import SubmitForm from "./SubmitForm";

export const dynamic = "force-dynamic";

export default async function SubmitPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!acc.approved && !isStaff(acc.role)) redirect("/pending");
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, select: { id: true, name: true } });
  return <SubmitForm sections={sections} authorName={acc.name} />;
}
IJRI_EOF

cat > src/app/submit/SubmitForm.tsx << 'IJRI_EOF'
"use client";
import { useState } from "react";
import Link from "next/link";
import { T, Eyebrow } from "@/lib/ui";
import { IconFeather } from "@/lib/icons";

export default function SubmitForm({ sections, authorName }: { sections: { id: string; name: string }[]; authorName: string }) {
  const [title, setTitle] = useState("");
  const [authors, setAuthors] = useState(authorName);
  const [affiliation, setAffiliation] = useState("");
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? "");
  const [abstract, setAbstract] = useState("");
  const [bodyHtml, setBodyHtml] = useState("");
  const [err, setErr] = useState("");
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const r = await fetch("/api/submissions", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, authorNames: authors, affiliation, sectionId, abstract, bodyHtml }),
    });
    setLoading(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setErr(d.error ?? "Submission failed"); return; }
    setDone(true);
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };
  const lbl: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted, display: "block", marginTop: 16 };

  if (done) {
    return (
      <main style={{ maxWidth: 620, margin: "60px auto", padding: "0 20px", textAlign: "center" }}>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30 }}>Submission received</h1>
        <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>Your manuscript has been submitted for double-blind peer review. You&rsquo;ll be notified as it moves through the editorial process.</p>
        <p style={{ marginTop: 20 }}><Link href="/" style={{ fontFamily: T.sans, fontSize: 13, textDecoration: "underline", textTransform: "uppercase", letterSpacing: "0.06em" }}>Back to the journal</Link></p>
      </main>
    );
  }

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconFeather size={22} /><Eyebrow inverse>Submit</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,36px)", margin: "12px 0 6px" }}>Submit a manuscript</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 10px" }}>Please review the <Link href="/for-authors" style={{ textDecoration: "underline", color: T.ink }}>author guidelines</Link> before submitting.</p>
      <form onSubmit={submit}>
        <label style={lbl}>Title<input style={input} value={title} onChange={(e) => setTitle(e.target.value)} required /></label>
        <label style={lbl}>Author(s)<input style={input} value={authors} onChange={(e) => setAuthors(e.target.value)} required /></label>
        <label style={lbl}>Affiliation<input style={input} value={affiliation} onChange={(e) => setAffiliation(e.target.value)} /></label>
        <label style={lbl}>Section
          <select style={input} value={sectionId} onChange={(e) => setSectionId(e.target.value)} required>
            {sections.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </label>
        <label style={lbl}>Abstract<textarea style={{ ...input, minHeight: 110, resize: "vertical" }} value={abstract} onChange={(e) => setAbstract(e.target.value)} required /></label>
        <label style={lbl}>Manuscript body (HTML or plain text)
          <textarea style={{ ...input, minHeight: 220, resize: "vertical", fontFamily: T.serif }} value={bodyHtml} onChange={(e) => setBodyHtml(e.target.value)} required />
        </label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ marginTop: 22, padding: "12px 22px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Submitting…" : "Submit for review"}
        </button>
      </form>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Admin + submissions written. Now run:"
echo "  npm run build"
echo "  git add . && git commit -m 'Admin, submissions, approval flow' && git push origin main"
