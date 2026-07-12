#!/usr/bin/env bash
# ==========================================================================
# IJRI — stage 2a: transparent favicon, category (section) browsing, and login.
#   - replaces icon.png with a transparent version
#   - /sections and /sections/[slug] browse-by-category pages
#   - /login and /register pages + header sign-in / sign-out state
# Run in the repo:  bash build-stage2a.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Stage 2a: favicon, categories, login..."
mkdir -p src/app/sections "src/app/sections/[slug]" src/app/login src/app/register

# ---- transparent favicon (decoded from embedded base64) ----
base64 -d > src/app/icon.png << 'ICON_EOF'
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
ICON_EOF
echo "  favicon replaced (transparent)"

# ---- SessionProvider wrapper ----
cat > src/app/providers.tsx << 'IJRI_EOF'
"use client";
import { SessionProvider } from "next-auth/react";
export function Providers({ children }: { children: React.ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
IJRI_EOF

# ---- layout with auth state + Sections nav ----
cat > src/app/layout.tsx << 'IJRI_EOF'
import Link from "next/link";
import { T } from "@/lib/ui";
import { auth, signOut } from "@/auth";
import { Providers } from "./providers";

export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary, double-blind peer-reviewed research journal.",
};

const CURRENT = "Volume 1, Issue 1 · July 2026";
const NAV: [string, string][] = [
  ["/", "Home"],
  ["/archives", "Archives"],
  ["/sections", "Sections"],
  ["/editorial-board", "Editorial Board"],
  ["/for-authors", "For Authors"],
];

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const user = session?.user as { name?: string | null } | undefined;

  return (
    <html lang="en">
      <body style={{ margin: 0, background: T.paper, color: T.ink }}>
        <style>{`
          * { box-sizing: border-box; }
          a { color: inherit; text-decoration: none; }
          .nav a:hover { background:#ececec; }
          .cardtitle { text-decoration: underline transparent; text-underline-offset: 3px; transition: text-decoration-color .15s; }
          a:hover .cardtitle { text-decoration-color: ${T.ink}; }
          .body h2 { font-family:${T.serif}; font-size:22px; margin:28px 0 10px; }
          .body p { font-family:${T.serif}; font-size:18.5px; line-height:1.68; margin:0 0 20px; color:#1a1a1a; }
          .body blockquote { font-family:${T.serif}; font-style:italic; border-left:3px solid ${T.ink}; margin:24px 0; padding:4px 0 4px 18px; color:#333; }
          .body p:first-of-type::first-letter { font-family:${T.serif}; float:left; font-size:62px; line-height:.82; padding:6px 10px 0 0; font-weight:600; }
          .linkbtn { background:none; border:none; padding:0; cursor:pointer; font:inherit; color:inherit; }
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} .utilbar{font-size:10px !important;} }
        `}</style>

        <Providers>
          <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
            <div style={{ borderBottom: `1px solid ${T.rule}` }}>
              <div className="utilbar" style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
                <span>e-ISSN: applied for</span>
                {user ? (
                  <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
                    <span style={{ color: T.ink }}>{user.name}</span>
                    <form action={async () => { "use server"; await signOut({ redirectTo: "/" }); }}>
                      <button className="linkbtn" style={{ textTransform: "uppercase", letterSpacing: "0.06em", textDecoration: "underline", textUnderlineOffset: 2 }}>Sign out</button>
                    </form>
                  </span>
                ) : (
                  <Link href="/login" style={{ textDecoration: "underline", textUnderlineOffset: 2 }}>Sign in</Link>
                )}
              </div>
            </div>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "20px 20px 14px", textAlign: "center" }}>
              <Link href="/" style={{ display: "inline-block" }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/logo-stacked.png" alt="International Journal of Research and Innovation" style={{ height: "clamp(64px,11vw,96px)", width: "auto" }} />
              </Link>
            </div>
            <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
                Current issue · {CURRENT}
              </div>
            </div>
            <nav className="nav" style={{ background: T.faint }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
                {NAV.map(([href, label]) => (
                  <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
                ))}
              </div>
            </nav>
          </header>

          {children}

          <footer style={{ borderTop: `1px solid ${T.ink}`, background: T.ink, marginTop: 40 }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "34px 20px", textAlign: "center" }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 30, width: "auto", opacity: 0.95 }} />
              <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: "#9a9a9a", marginTop: 16 }}>
                ijrein.org · e-ISSN applied for · © 2026 International Journal of Research and Innovation
              </div>
            </div>
          </footer>
        </Providers>
      </body>
    </html>
  );
}
IJRI_EOF

# ---- sections index ----
cat > src/app/sections/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Sections() {
  const sections = await prisma.section.findMany({
    orderBy: { name: "asc" },
    include: { articles: { where: { status: "PUBLISHED" }, select: { id: true } } },
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Sections</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 8px" }}>Browse by section</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 24px" }}>
        The journal publishes across the sciences, engineering, management, and the social sciences.
      </p>
      <div style={{ borderTop: `1px solid ${T.ink}` }}>
        {sections.map((s) => (
          <Link key={s.id} href={`/sections/${s.slug}`} style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
            <span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 21 }}>{s.name}</span>
            <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, textTransform: "uppercase", letterSpacing: "0.06em" }}>{s.articles.length} article{s.articles.length === 1 ? "" : "s"}</span>
          </Link>
        ))}
      </div>
    </main>
  );
}
IJRI_EOF

# ---- section detail ----
cat > "src/app/sections/[slug]/page.tsx" << 'IJRI_EOF'
import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function SectionPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const section = await prisma.section.findUnique({
    where: { slug },
    include: {
      articles: { where: { status: "PUBLISHED" }, include: { issue: true }, orderBy: { publishedAt: "desc" } },
    },
  });
  if (!section) notFound();

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <Link href="/sections" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← All sections</Link>
      <div style={{ marginTop: 16 }}><Eyebrow inverse>Section</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 20px" }}>{section.name}</h1>
      {section.articles.length === 0 ? (
        <p style={{ fontFamily: T.serif, color: T.muted }}>No articles published in this section yet.</p>
      ) : (
        section.articles.map((a) => (
          <Link key={a.id} href={`/articles/${a.id}`} style={{ display: "block", padding: "18px 0", borderTop: `1px solid ${T.rule}` }}>
            <h3 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 20, lineHeight: 1.25, margin: "0 0 6px" }}>{a.title}</h3>
            <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.5, color: "#333", margin: "0 0 6px" }}>{a.abstract}</p>
            <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.authorNames} · Vol {a.issue?.volume}, Issue {a.issue?.number} · pp. {pages(a)}</div>
          </Link>
        ))
      )}
    </main>
  );
}
IJRI_EOF

# ---- login ----
cat > src/app/login/page.tsx << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { T } from "@/lib/ui";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const res = await signIn("credentials", { email, password, redirect: false });
    setLoading(false);
    if (res?.error) setErr("Invalid email or password.");
    else { router.push("/"); router.refresh(); }
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "11px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };

  return (
    <main style={{ maxWidth: 380, margin: "60px auto", padding: "0 20px" }}>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "0 0 6px" }}>Sign in</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 22px" }}>Access full articles, submissions, and the editorial desk.</p>
      <form onSubmit={submit}>
        <label style={{ fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted }}>Email
          <input style={input} type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <div style={{ height: 16 }} />
        <label style={{ fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted }}>Password
          <input style={input} type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ width: "100%", marginTop: 20, padding: "12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 20 }}>
        No account? <Link href="/register" style={{ textDecoration: "underline", color: T.ink }}>Register</Link>
      </p>
    </main>
  );
}
IJRI_EOF

# ---- register ----
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
    router.push("/"); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "11px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };
  const lbl: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted };

  return (
    <main style={{ maxWidth: 380, margin: "60px auto", padding: "0 20px" }}>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "0 0 6px" }}>Create account</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 22px" }}>Register as an author to submit manuscripts.</p>
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

echo ""
echo "Stage 2a written. Now run:"
echo "  npm run build"
echo "  git add . && git commit -m 'Stage 2a: favicon, sections, login' && git push origin main"
