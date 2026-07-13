#!/usr/bin/env bash
# ==========================================================================
# IJRI — privacy-respecting analytics (aggregate only, no per-user profiles).
# Records article VIEW / DOWNLOAD events with a coarse device class (desktop/
# mobile/tablet/bot) parsed server-side. No user IDs, no IPs, no full UA are
# stored. Admin dashboard shows totals, top articles, and device split.
#
# This script writes NEW files only (safe). Two one-line insertions into your
# existing files are described at the end for Claude Code to place.
# Run in repo:  bash build-analytics.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Analytics (privacy-respecting)..."
mkdir -p src/lib src/app/api/track src/app/admin/analytics src/app/_components

# ---------------------------------------------------------------- device class (server-side, coarse)
cat > src/lib/device.ts << 'IJRI_EOF'
// Coarse device classification from a User-Agent string. Deliberately lossy:
// we keep only a category, never the raw UA, IP, or any identifier.
export function deviceClass(ua: string | null | undefined): string {
  const s = (ua ?? "").toLowerCase();
  if (!s) return "unknown";
  if (/bot|crawler|spider|slurp|bingpreview|facebookexternalhit|headless/.test(s)) return "bot";
  if (/ipad|tablet|kindle|silk|playbook/.test(s)) return "tablet";
  if (/mobi|iphone|ipod|android.*mobile|windows phone/.test(s)) return "mobile";
  if (/android/.test(s)) return "tablet";
  return "desktop";
}
IJRI_EOF

# ---------------------------------------------------------------- track helper (fire-and-forget)
cat > src/lib/track.ts << 'IJRI_EOF'
import { prisma } from "./prisma";
import type { EventType } from "@prisma/client";

// Fire-and-forget. Never throws into the request path; analytics must never
// break a page render or a download.
export async function recordEvent(articleId: string, type: EventType, device?: string) {
  try {
    await prisma.articleEvent.create({ data: { articleId, type, device: device ?? null } });
  } catch {
    /* swallow — analytics is best-effort */
  }
}
IJRI_EOF

# ---------------------------------------------------------------- /api/track (server parses UA)
cat > src/app/api/track/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { deviceClass } from "@/lib/device";
import type { EventType } from "@prisma/client";

const ALLOWED: EventType[] = ["VIEW", "DOWNLOAD", "SHARE"];

export async function POST(req: Request) {
  const b = await req.json().catch(() => null);
  const articleId = String(b?.articleId ?? "");
  const type = String(b?.type ?? "") as EventType;
  if (!articleId || !ALLOWED.includes(type)) return Response.json({ ok: false }, { status: 400 });

  const device = deviceClass(req.headers.get("user-agent"));
  try {
    // Only record events for real, published articles.
    const exists = await prisma.article.findFirst({ where: { id: articleId, status: "PUBLISHED" }, select: { id: true } });
    if (exists) await prisma.articleEvent.create({ data: { articleId, type, device } });
  } catch {
    /* best-effort */
  }
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- <TrackView> client beacon
cat > src/app/_components/TrackView.tsx << 'IJRI_EOF'
"use client";
import { useEffect, useRef } from "react";

// Drop <TrackView articleId={article.id} /> into the article reader page.
// Fires exactly once per mount; no cookies, no identifiers.
export default function TrackView({ articleId }: { articleId: string }) {
  const done = useRef(false);
  useEffect(() => {
    if (done.current) return;
    done.current = true;
    const body = JSON.stringify({ articleId, type: "VIEW" });
    fetch("/api/track", { method: "POST", headers: { "Content-Type": "application/json" }, body, keepalive: true }).catch(() => {});
  }, [articleId]);
  return null;
}
IJRI_EOF

# ---------------------------------------------------------------- admin analytics dashboard
cat > src/app/admin/analytics/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconInfo } from "@/lib/icons";

export const dynamic = "force-dynamic";

export default async function Analytics() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");

  const since = new Date(Date.now() - 30 * 86400000);
  const [views, downloads, views30] = await Promise.all([
    prisma.articleEvent.count({ where: { type: "VIEW" } }),
    prisma.articleEvent.count({ where: { type: "DOWNLOAD" } }),
    prisma.articleEvent.count({ where: { type: "VIEW", createdAt: { gte: since } } }),
  ]);

  const topRaw = await prisma.articleEvent.groupBy({
    by: ["articleId"], where: { type: "VIEW" }, _count: { _all: true },
    orderBy: { _count: { articleId: "desc" } }, take: 10,
  });
  const arts = await prisma.article.findMany({ where: { id: { in: topRaw.map((t) => t.articleId) } }, select: { id: true, title: true } });
  const titleOf = Object.fromEntries(arts.map((a) => [a.id, a.title]));
  const top = topRaw.map((t) => ({ title: titleOf[t.articleId] ?? "—", count: t._count._all }));
  const topMax = Math.max(1, ...top.map((t) => t.count));

  const devRaw = await prisma.articleEvent.groupBy({ by: ["device"], where: { type: "VIEW" }, _count: { _all: true } });
  const devices = devRaw.map((d) => ({ label: d.device ?? "unknown", count: d._count._all })).sort((a, b) => b.count - a.count);
  const devTotal = Math.max(1, devices.reduce((s, d) => s + d.count, 0));

  const Stat = ({ n, label }: { n: number; label: string }) => (
    <div style={{ border: `1px solid ${T.ink}`, padding: "18px 20px" }}>
      <div style={{ fontFamily: T.serif, fontSize: 40, fontWeight: 600, lineHeight: 1 }}>{n.toLocaleString()}</div>
      <div style={{ fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted, marginTop: 6 }}>{label}</div>
    </div>
  );

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Link href="/admin" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Admin</Link>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 4px" }}>Readership analytics</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 22px" }}>Aggregate figures only. No individual reading histories are stored.</p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14, marginBottom: 30 }}>
        <Stat n={views} label="Total article views" />
        <Stat n={views30} label="Views · last 30 days" />
        <Stat n={downloads} label="PDF downloads" />
      </div>

      <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8 }}>Most read articles</h2>
      {top.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 16, color: T.muted, marginTop: 12 }}>No views recorded yet.</p>
      ) : top.map((t, i) => (
        <div key={i} style={{ padding: "12px 0", borderBottom: `1px solid ${T.rule}` }}>
          <div style={{ display: "flex", justifyContent: "space-between", gap: 12, marginBottom: 6 }}>
            <span style={{ fontFamily: T.serif, fontSize: 16 }}>{t.title}</span>
            <span style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>{t.count.toLocaleString()}</span>
          </div>
          <div style={{ height: 6, background: T.g200 }}><div style={{ height: "100%", width: `${Math.round((t.count / topMax) * 100)}%`, background: T.ink }} /></div>
        </div>
      ))}

      <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8, marginTop: 34 }}>Device breakdown</h2>
      {devices.map((d) => (
        <div key={d.label} style={{ display: "flex", alignItems: "center", gap: 12, padding: "10px 0", borderBottom: `1px solid ${T.rule}` }}>
          <span style={{ fontFamily: T.sans, fontSize: 13, width: 90, textTransform: "capitalize" }}>{d.label}</span>
          <div style={{ flex: 1, height: 6, background: T.g200 }}><div style={{ height: "100%", width: `${Math.round((d.count / devTotal) * 100)}%`, background: T.ink }} /></div>
          <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, width: 54, textAlign: "right" }}>{Math.round((d.count / devTotal) * 100)}%</span>
        </div>
      ))}

      <div style={{ display: "flex", gap: 10, alignItems: "flex-start", marginTop: 30, background: T.g50, border: `1px solid ${T.rule}`, padding: "14px 16px" }}>
        <IconInfo size={18} />
        <p style={{ fontFamily: T.sans, fontSize: 12.5, lineHeight: 1.55, color: T.muted, margin: 0 }}>
          These analytics are intentionally aggregate. IJRI records only a page-view or download count and a coarse device class, with no user identity, IP address, or reading history attached — consistent with the journal&rsquo;s Privacy Policy and India&rsquo;s DPDP Act. To attribute activity to named individuals you would need explicit, disclosed consent and a lawful basis; that is a deliberate design choice, not a limitation.
        </p>
      </div>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Analytics written (new files only)."
echo ""
echo "TWO one-line insertions for Claude Code to place into existing files:"
echo "  1) In src/app/articles/[id]/page.tsx (the reader page), inside the"
echo "     returned JSX, add near the top of the article:"
echo "        import TrackView from \"@/app/_components/TrackView\";"
echo "        <TrackView articleId={article.id} />"
echo "  2) In src/app/api/articles/[id]/pdf/route.ts, AFTER the entitlement"
echo "     check passes and before returning the signed URL, add:"
echo "        import { recordEvent } from \"@/lib/track\";"
echo "        import { deviceClass } from \"@/lib/device\";"
echo "        void recordEvent(article.id, \"DOWNLOAD\", deviceClass(req.headers.get(\"user-agent\")));"
echo ""
echo "Then:  npm run build"
