#!/usr/bin/env bash
# ==========================================================================
# IJRI — structured backend.
#   /dashboard         role-aware hub: sidebar menu + at-a-glance overview
#   BackendNav         the menu (highlights the active feature)
#   top-bar button     becomes a single "Dashboard" for any logged-in user
# Menu links point to the real feature pages (/admin, /editor, /admin/analytics,
# /my-submissions, /submit, /submit/word) so nothing is duplicated.
# Run in repo:  bash build-backend.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Structured backend (dashboard + menus)..."
mkdir -p src/app/dashboard

# ---------------------------------------------------------------- patch top-bar button -> Dashboard
if [ -f src/app/layout.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8");
if (s.includes(`["/dashboard", "Dashboard"]`)) { console.log("  layout: already points to /dashboard"); }
else {
  const re = /function dash\(role\?: string\)[\s\S]*?\n}\n/;
  const next = `function dash(role?: string): [string, string] | null {\n  if (!role) return null;\n  return ["/dashboard", "Dashboard"];\n}\n`;
  if (re.test(s)) { s = s.replace(re, next); fs.writeFileSync(p, s); console.log("  layout: top-bar button -> Dashboard"); }
  else { console.log("  WARN: dash() not found in layout.tsx — add a /dashboard link manually"); }
}
NODE
else
  echo "  WARN: src/app/layout.tsx not found (run from repo root)"
fi

# ---------------------------------------------------------------- backend menu (client, active highlight)
cat > src/app/dashboard/BackendNav.tsx << 'IJRI_EOF'
"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { T } from "@/lib/ui";
import { IconLayers, IconDoc, IconFeather, IconUsers, IconShield, IconInfo, IconArchive } from "@/lib/icons";

type Item = { href: string; label: string; icon: React.ReactNode };

const ROLE_LABEL: Record<string, string> = { ADMIN: "Administrator", CHIEF_EDITOR: "Editor-in-Chief", EDITOR: "Editor", AUTHOR: "Author" };

export default function BackendNav({ role, name }: { role: string; name: string }) {
  const path = usePathname();
  const items: Item[] = [{ href: "/dashboard", label: "Overview", icon: <IconLayers size={16} /> }];

  if (role === "AUTHOR") {
    items.push(
      { href: "/my-submissions", label: "My submissions", icon: <IconDoc size={16} /> },
      { href: "/submit", label: "New submission", icon: <IconFeather size={16} /> },
      { href: "/submit/word", label: "Upload Word doc", icon: <IconArchive size={16} /> },
    );
  }
  if (role === "EDITOR") {
    items.push({ href: "/editor", label: "Review desk", icon: <IconDoc size={16} /> });
  }
  if (role === "CHIEF_EDITOR" || role === "ADMIN") {
    items.push(
      { href: "/editor", label: "Review desk", icon: <IconDoc size={16} /> },
      { href: "/admin", label: "Admin panel", icon: <IconUsers size={16} /> },
      { href: "/admin/analytics", label: "Analytics", icon: <IconInfo size={16} /> },
    );
  }

  return (
    <nav aria-label="Backend" style={{ fontFamily: T.sans }}>
      <div style={{ border: `1px solid ${T.rule}`, background: T.g50, padding: "14px 14px 8px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, paddingBottom: 12, borderBottom: `1px solid ${T.rule}`, marginBottom: 8 }}>
          <span style={{ width: 34, height: 34, background: T.ink, color: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 15 }}>
            {name.split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase()}
          </span>
          <span>
            <span style={{ display: "block", fontSize: 13, color: T.ink, lineHeight: 1.2 }}>{name}</span>
            <span style={{ display: "block", fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>{ROLE_LABEL[role] ?? role}</span>
          </span>
        </div>
        {items.map((it) => {
          const active = path === it.href;
          return (
            <Link key={it.href + it.label} href={it.href} style={{
              display: "flex", alignItems: "center", gap: 10, padding: "10px 10px", marginBottom: 2,
              fontSize: 13.5, color: active ? T.paper : T.ink, background: active ? T.ink : "transparent",
            }}>
              <span style={{ opacity: active ? 1 : 0.7, display: "inline-flex" }}>{it.icon}</span>{it.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- dashboard hub (server, role-aware stats)
cat > src/app/dashboard/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { T, Eyebrow } from "@/lib/ui";
import { IconArrow } from "@/lib/icons";
import BackendNav from "./BackendNav";

export const dynamic = "force-dynamic";

type Stat = { n: number; label: string; href?: string; accent?: boolean };

export default async function Dashboard() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const role = acc.role;
  const isAdmin = role === "ADMIN" || role === "CHIEF_EDITOR";

  let stats: Stat[] = [];
  let actions: { href: string; label: string; desc: string }[] = [];

  if (isAdmin) {
    const [pending, queue, revisions, published, subs, views] = await Promise.all([
      prisma.user.count({ where: { approved: false } }),
      prisma.article.count({ where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } } }),
      prisma.article.count({ where: { status: "REVISION_REQUESTED" } }),
      prisma.article.count({ where: { status: "PUBLISHED" } }),
      prisma.subscription.count({ where: { status: "ACTIVE", endsAt: { gte: new Date() } } }),
      prisma.articleEvent.count({ where: { type: "VIEW" } }),
    ]);
    stats = [
      { n: pending, label: "Users awaiting approval", href: "/admin", accent: pending > 0 },
      { n: queue, label: "Manuscripts in the queue", href: "/editor", accent: queue > 0 },
      { n: revisions, label: "Out for revision" },
      { n: published, label: "Published articles" },
      { n: subs, label: "Active subscriptions" },
      { n: views, label: "Total article views", href: "/admin/analytics" },
    ];
    actions = [
      { href: "/admin", label: "Admin panel", desc: "Approve authors, manage sections and roles." },
      { href: "/editor", label: "Review desk", desc: "Read manuscripts, record reviews, publish or reject." },
      { href: "/admin/analytics", label: "Analytics", desc: "Aggregate readership and downloads." },
    ];
  } else if (role === "EDITOR") {
    const [queue, myReviews] = await Promise.all([
      prisma.article.count({ where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } } }),
      prisma.review.count({ where: { editorId: acc.id } }),
    ]);
    stats = [
      { n: queue, label: "Manuscripts in the queue", href: "/editor", accent: queue > 0 },
      { n: myReviews, label: "Reviews you've recorded" },
    ];
    actions = [{ href: "/editor", label: "Review desk", desc: "Open the queue and record your reviews." }];
  } else {
    const [mine, revisions, published] = await Promise.all([
      prisma.article.count({ where: { submittedById: acc.id } }),
      prisma.article.count({ where: { submittedById: acc.id, status: "REVISION_REQUESTED" } }),
      prisma.article.count({ where: { submittedById: acc.id, status: "PUBLISHED" } }),
    ]);
    stats = [
      { n: mine, label: "Your submissions", href: "/my-submissions" },
      { n: revisions, label: "Awaiting your revision", href: "/my-submissions", accent: revisions > 0 },
      { n: published, label: "Published" },
    ];
    actions = [
      { href: "/submit", label: "New submission", desc: "Submit a manuscript using the form." },
      { href: "/submit/word", label: "Upload Word document", desc: "Convert a .docx into the journal style." },
      { href: "/my-submissions", label: "My submissions", desc: "Track status and respond to editor feedback." },
    ];
  }

  return (
    <main style={{ maxWidth: 1080, margin: "0 auto", padding: "36px 20px 56px" }}>
      <style>{`
        .bk-grid { display:grid; grid-template-columns:230px 1fr; gap:28px; align-items:start; }
        .bk-stats { display:grid; grid-template-columns:repeat(3,1fr); gap:14px; }
        @media (max-width:760px){ .bk-grid{ grid-template-columns:1fr; } .bk-stats{ grid-template-columns:1fr 1fr; } }
        @media (max-width:460px){ .bk-stats{ grid-template-columns:1fr; } }
      `}</style>

      <Eyebrow inverse>Backend</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "10px 0 22px" }}>Welcome, {acc.name.split(/\s+/)[0]}</h1>

      <div className="bk-grid">
        <BackendNav role={role} name={acc.name} />

        <div>
          <div className="bk-stats">
            {stats.map((s, i) => {
              const inner = (
                <div style={{ border: s.accent ? `2px solid ${T.ink}` : `1px solid ${T.rule}`, padding: "18px 18px", background: s.accent ? T.g50 : T.paper, height: "100%" }}>
                  <div style={{ fontFamily: T.serif, fontSize: 38, fontWeight: 600, lineHeight: 1 }}>{s.n.toLocaleString()}</div>
                  <div style={{ fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted, marginTop: 6 }}>{s.label}</div>
                </div>
              );
              return s.href ? <Link key={i} href={s.href}>{inner}</Link> : <div key={i}>{inner}</div>;
            })}
          </div>

          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8, margin: "34px 0 4px" }}>Go to</h2>
          {actions.map((a) => (
            <Link key={a.href + a.label} href={a.href} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12, padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <span>
                <span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 19, display: "block" }}>{a.label}</span>
                <span style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>{a.desc}</span>
              </span>
              <IconArrow size={17} />
            </Link>
          ))}
        </div>
      </div>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Backend written. Now run:  npm run build"
