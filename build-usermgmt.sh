#!/usr/bin/env bash
# ==========================================================================
# IJRI — User & Section management.
#   /admin            -> redirects to /admin/users
#   /admin/users      tabs: Super admins · Chief editor · Editors · Authors
#                     approve, change role, one-chief rule, info@ protected,
#                     names link to /people/[id]
#   /admin/sections   add / remove sections
#   nav "Admin panel" -> "User management" + "Section management"
#   nav "Analytics"   -> "Usage analytics"
# Run in repo:  bash build-usermgmt.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "User & Section management..."

BASE="src/app"
[ -d "src/app/(backend)" ] && BASE="src/app/(backend)"
mkdir -p "$BASE/admin/users" "$BASE/admin/sections" src/app/api/admin/users src/app/api/admin/sections
echo "  admin pages -> $BASE/admin"

# ---------------------------------------------------------------- users API
cat > src/app/api/admin/users/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

const SUPER = "info@ijrein.org";
const ROLES = ["AUTHOR", "EDITOR", "CHIEF_EDITOR", "ADMIN"];

async function requireManager(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return { err: unauthorized() };
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return { err: forbidden("Managers only") };
  return { acc };
}

export async function GET(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const users = await prisma.user.findMany({
    orderBy: [{ approved: "asc" }, { createdAt: "asc" }],
    select: { id: true, name: true, email: true, role: true, approved: true, affiliation: true, designation: true, image: true, createdAt: true },
  });
  return Response.json({ users });
}

export async function PATCH(req: Request) {
  const { acc, err } = await requireManager(req);
  if (err) return err;

  const b = await req.json().catch(() => null);
  const userId = String(b?.userId ?? "");
  const action = String(b?.action ?? "");
  const target = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, email: true, role: true } });
  if (!target) return Response.json({ error: "User not found" }, { status: 404 });

  const isSuper = target.email === SUPER;

  if (action === "approve") { await prisma.user.update({ where: { id: userId }, data: { approved: true } }); return Response.json({ ok: true }); }
  if (action === "unapprove") {
    if (isSuper) return Response.json({ error: "The super admin account is protected" }, { status: 403 });
    await prisma.user.update({ where: { id: userId }, data: { approved: false } });
    return Response.json({ ok: true });
  }
  if (action === "role") {
    const role = String(b?.role ?? "");
    if (!ROLES.includes(role)) return Response.json({ error: "Invalid role" }, { status: 400 });
    if (isSuper && role !== "ADMIN") return Response.json({ error: "The super admin account must remain an administrator" }, { status: 403 });
    if (role === "CHIEF_EDITOR") {
      // only one chief editor
      await prisma.user.updateMany({ where: { role: "CHIEF_EDITOR", id: { not: userId } }, data: { role: "EDITOR" } });
    }
    await prisma.user.update({ where: { id: userId }, data: { role: role as never, approved: true } });
    return Response.json({ ok: true });
  }
  return Response.json({ error: "Unknown action" }, { status: 400 });
}
IJRI_EOF

# ---------------------------------------------------------------- sections API
cat > src/app/api/admin/sections/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

async function requireManager(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return { err: unauthorized() };
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return { err: forbidden("Managers only") };
  return { acc };
}

export async function GET(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, include: { _count: { select: { articles: true } } } });
  return Response.json({ sections: sections.map((s) => ({ id: s.id, name: s.name, slug: s.slug, articles: s._count.articles })) });
}

export async function POST(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const b = await req.json().catch(() => null);
  const name = String(b?.name ?? "").trim();
  if (!name) return Response.json({ error: "Name is required" }, { status: 400 });
  const s = slug(name);
  const existing = await prisma.section.findFirst({ where: { OR: [{ name }, { slug: s }] }, select: { id: true } });
  if (existing) return Response.json({ error: "That section already exists" }, { status: 409 });
  await prisma.section.create({ data: { name, slug: s } });
  return Response.json({ ok: true }, { status: 201 });
}

export async function DELETE(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const b = await req.json().catch(() => null);
  const id = String(b?.id ?? "");
  const count = await prisma.article.count({ where: { sectionId: id } });
  if (count > 0) return Response.json({ error: `Cannot delete — ${count} article(s) use this section` }, { status: 409 });
  await prisma.section.delete({ where: { id } });
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- /admin redirect
cat > "$BASE/admin/page.tsx" << 'IJRI_EOF'
import { redirect } from "next/navigation";
export default function Admin() { redirect("/admin/users"); }
IJRI_EOF

# ---------------------------------------------------------------- users page (server gate)
cat > "$BASE/admin/users/page.tsx" << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import UserManagement from "./UserManagement";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") redirect("/dashboard");
  return <UserManagement />;
}
IJRI_EOF

cat > "$BASE/admin/users/UserManagement.tsx" << 'IJRI_EOF'
"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { T, Eyebrow, Chip } from "@/lib/ui";
import Avatar from "@/components/Avatar";

type U = { id: string; name: string; email: string; role: string; approved: boolean; affiliation: string | null; designation: string | null; image: string | null };

const TABS: [string, string][] = [["ADMIN", "Super admins"], ["CHIEF_EDITOR", "Chief editor"], ["EDITOR", "Editors"], ["AUTHOR", "Authors"]];
const ROLE_OPTS: [string, string][] = [["AUTHOR", "Author"], ["EDITOR", "Editor"], ["CHIEF_EDITOR", "Chief editor"], ["ADMIN", "Super admin"]];
const SUPER = "info@ijrein.org";

export default function UserManagement() {
  const [users, setUsers] = useState<U[]>([]);
  const [tab, setTab] = useState("AUTHOR");
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState("");

  async function load() { setLoading(true); try { const r = await fetch("/api/admin/users"); const d = await r.json(); setUsers(d.users ?? []); } catch { /* */ } setLoading(false); }
  useEffect(() => { load(); }, []);

  async function act(userId: string, body: Record<string, unknown>) {
    setMsg("");
    const r = await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId, ...body }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Action failed"); return; }
    load();
  }

  const pending = users.filter((u) => !u.approved).length;
  const shown = users.filter((u) => u.role === tab);

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><Eyebrow inverse>User management</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 4px" }}>Users &amp; access</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 18px" }}>{users.length} users{pending > 0 ? ` · ${pending} awaiting approval` : ""} · one Chief Editor allowed</p>

      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", borderBottom: `1px solid ${T.ink}`, marginBottom: 16 }}>
        {TABS.map(([key, label]) => {
          const n = users.filter((u) => u.role === key).length;
          return (
            <button key={key} onClick={() => setTab(key)} style={{ fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.03em", textTransform: "uppercase", padding: "9px 13px", cursor: "pointer", border: "none", background: tab === key ? T.ink : "transparent", color: tab === key ? T.paper : T.ink }}>{label} ({n})</button>
          );
        })}
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}
      {loading ? <p style={{ fontFamily: T.serif, color: T.muted }}>Loading…</p> : shown.length === 0 ? <p style={{ fontFamily: T.serif, color: T.muted }}>No users in this group.</p> : shown.map((u) => (
        <div key={u.id} style={{ display: "grid", gridTemplateColumns: "40px 1fr auto", gap: 12, alignItems: "center", padding: "14px 0", borderBottom: `1px solid ${T.rule}` }}>
          <Avatar image={u.image} name={u.name} size={40} />
          <div style={{ minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
              <Link href={`/people/${u.id}`} className="cardtitle" style={{ fontFamily: T.serif, fontSize: 17 }}>{u.name}</Link>
              {u.email === SUPER && <Chip>super admin</Chip>}
              {!u.approved && <Chip>pending</Chip>}
            </div>
            <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>{u.email}{u.designation ? ` · ${u.designation}` : ""}{u.affiliation ? ` · ${u.affiliation}` : ""}</div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap", justifyContent: "flex-end" }}>
            {!u.approved && <button onClick={() => act(u.id, { action: "approve" })} style={{ padding: "7px 12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", cursor: "pointer" }}>Approve</button>}
            <select value={u.role} disabled={u.email === SUPER} onChange={(e) => act(u.id, { action: "role", role: e.target.value })} style={{ fontFamily: T.sans, fontSize: 12.5, padding: "7px 8px", border: `1px solid ${T.ink}`, background: T.paper, opacity: u.email === SUPER ? 0.5 : 1 }}>
              {ROLE_OPTS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
        </div>
      ))}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- sections page
cat > "$BASE/admin/sections/page.tsx" << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import SectionManagement from "./SectionManagement";

export const dynamic = "force-dynamic";

export default async function SectionsPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") redirect("/dashboard");
  return <SectionManagement />;
}
IJRI_EOF

cat > "$BASE/admin/sections/SectionManagement.tsx" << 'IJRI_EOF'
"use client";
import { useEffect, useState } from "react";
import { T, Eyebrow } from "@/lib/ui";

type S = { id: string; name: string; slug: string; articles: number };

export default function SectionManagement() {
  const [sections, setSections] = useState<S[]>([]);
  const [name, setName] = useState("");
  const [msg, setMsg] = useState("");
  const [loading, setLoading] = useState(true);

  async function load() { setLoading(true); try { const r = await fetch("/api/admin/sections"); const d = await r.json(); setSections(d.sections ?? []); } catch { /* */ } setLoading(false); }
  useEffect(() => { load(); }, []);

  async function add() {
    if (!name.trim()) return; setMsg("");
    const r = await fetch("/api/admin/sections", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Failed"); return; }
    setName(""); load();
  }
  async function remove(id: string) {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Failed"); return; }
    load();
  }

  return (
    <main>
      <Eyebrow inverse>Section management</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 16px" }}>Sections</h1>

      <div style={{ display: "flex", gap: 10, marginBottom: 20, maxWidth: 480 }}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="New section name" onKeyDown={(e) => e.key === "Enter" && add()} style={{ flex: 1, fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, background: T.paper }} />
        <button onClick={add} style={{ padding: "10px 18px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Add</button>
      </div>
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}

      {loading ? <p style={{ fontFamily: T.serif, color: T.muted }}>Loading…</p> : sections.map((s) => (
        <div key={s.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "13px 0", borderBottom: `1px solid ${T.rule}` }}>
          <div>
            <span style={{ fontFamily: T.serif, fontSize: 18 }}>{s.name}</span>
            <span style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginLeft: 10 }}>{s.articles} article{s.articles === 1 ? "" : "s"}</span>
          </div>
          <button onClick={() => remove(s.id)} disabled={s.articles > 0} title={s.articles > 0 ? "Section has articles" : "Remove"} style={{ padding: "6px 12px", background: T.paper, color: s.articles > 0 ? T.muted : "#b00020", border: `1px solid ${s.articles > 0 ? T.rule : "#b00020"}`, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", cursor: s.articles > 0 ? "not-allowed" : "pointer" }}>Remove</button>
        </div>
      ))}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- nav: split admin + rename analytics
if [ -f src/components/BackendNav.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/components/BackendNav.tsx";
let s = fs.readFileSync(p, "utf8");
const from = `      { href: "/admin", label: "Admin panel", icon: <IconUsers size={16} /> },
      { href: "/admin/analytics", label: "Analytics", icon: <IconInfo size={16} /> },`;
const to = `      { href: "/admin/users", label: "User management", icon: <IconUsers size={16} /> },
      { href: "/admin/sections", label: "Section management", icon: <IconLayers size={16} /> },
      { href: "/admin/analytics", label: "Usage analytics", icon: <IconInfo size={16} /> },`;
if (s.includes(from)) { fs.writeFileSync(p, s.replace(from, to)); console.log("  nav: split admin + Usage analytics"); }
else if (s.includes(`/admin/users`)) console.log("  nav already updated");
else console.log("  WARN: nav admin block not found — update manually");
NODE
fi

# ---------------------------------------------------------------- dashboard: labels/hrefs
DASH=""
for c in "src/app/(backend)/dashboard/page.tsx" "src/app/dashboard/page.tsx"; do [ -f "$c" ] && DASH="$c" && break; done
if [ -n "$DASH" ]; then
  DASH="$DASH" node - << 'NODE'
const fs = require("fs"); const p = process.env.DASH; let s = fs.readFileSync(p, "utf8");
s = s.split(`href: "/admin", label: "Admin panel", desc: "Approve authors, manage sections and roles." }`).join(`href: "/admin/users", label: "User management", desc: "Approve users and manage roles." }`);
s = s.split(`label: "Analytics", desc: "Readership, downloads and engagement." }`).join(`label: "Usage analytics", desc: "Views, downloads and engagement." }`);
s = s.split(`{ n: pending, label: "Users awaiting approval", href: "/admin", accent: pending > 0 }`).join(`{ n: pending, label: "Users awaiting approval", href: "/admin/users", accent: pending > 0 }`);
fs.writeFileSync(p, s); console.log("  dashboard labels/hrefs updated");
NODE
fi

echo ""
echo "User & Section management written. Now run:  npm run build"
