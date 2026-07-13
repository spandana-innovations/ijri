#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#5) real tracking + detailed analytics.
#   - middleware records VIEW (/articles/:id) and DOWNLOAD (/api/articles/:id/pdf)
#     server-side, so the paywalled article page needs no edit. Prefetches are
#     ignored. Only a coarse device class is stored (no IP, no identity).
#   - /admin/analytics rebuilt: totals, 14-day trend, top articles, per-section,
#     top downloads, device split.
# Run in repo:  bash build-analytics2.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Tracking + detailed analytics..."

# ---------------------------------------------------------------- middleware (view/download beacon)
cat > src/middleware.ts << 'IJRI_EOF'
import { NextResponse, type NextRequest } from "next/server";

export const config = { matcher: ["/articles/:id", "/api/articles/:id/pdf"] };

export function middleware(req: NextRequest) {
  const res = NextResponse.next();
  // ignore prefetches so hovering a link doesn't inflate counts
  if (req.headers.get("next-router-prefetch") || req.headers.get("purpose") === "prefetch") return res;

  const path = req.nextUrl.pathname;
  let articleId = "";
  let type: "VIEW" | "DOWNLOAD" | "" = "";
  let m = path.match(/^\/articles\/([^/]+)$/);
  if (m) { articleId = m[1]; type = "VIEW"; }
  else { m = path.match(/^\/api\/articles\/([^/]+)\/pdf$/); if (m) { articleId = m[1]; type = "DOWNLOAD"; } }

  if (articleId && type) {
    // fire-and-forget to our own tracking endpoint; forward the real UA
    fetch(req.nextUrl.origin + "/api/track", {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-ua": req.headers.get("user-agent") ?? "" },
      body: JSON.stringify({ articleId, type }),
    }).catch(() => {});
  }
  return res;
}
IJRI_EOF

# ---------------------------------------------------------------- /api/track: honour forwarded UA
if [ -f src/app/api/track/route.ts ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/app/api/track/route.ts";
let s = fs.readFileSync(p, "utf8");
const from = `deviceClass(req.headers.get("user-agent"))`;
const to = `deviceClass(req.headers.get("x-ua") || req.headers.get("user-agent"))`;
if (s.includes(from)) { fs.writeFileSync(p, s.replace(from, to)); console.log("  /api/track: uses forwarded UA"); }
else if (s.includes(`x-ua`)) console.log("  /api/track already updated");
else console.log("  WARN: could not update /api/track UA line");
NODE
else
  echo "  WARN: /api/track not found (run build-analytics.sh first)"
fi

# ---------------------------------------------------------------- detailed analytics page
ANDIR=""
for c in "src/app/(backend)/admin/analytics" "src/app/admin/analytics"; do
  [ -d "$c" ] && ANDIR="$c" && break
done
[ -n "$ANDIR" ] || { ANDIR="src/app/admin/analytics"; mkdir -p "$ANDIR"; }
echo "  analytics page -> $ANDIR"

cat > "$ANDIR/page.tsx" << 'IJRI_EOF'
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
  if (!isStaff(acc.role)) redirect("/dashboard");

  const now = Date.now();
  const since30 = new Date(now - 30 * 86400000);
  const since14 = new Date(now - 14 * 86400000);

  const [views, downloads, views30] = await Promise.all([
    prisma.articleEvent.count({ where: { type: "VIEW" } }),
    prisma.articleEvent.count({ where: { type: "DOWNLOAD" } }),
    prisma.articleEvent.count({ where: { type: "VIEW", createdAt: { gte: since30 } } }),
  ]);

  // per-article views (bounded by number of articles)
  const perArticle = await prisma.articleEvent.groupBy({ by: ["articleId"], where: { type: "VIEW" }, _count: { _all: true } });
  const perDownload = await prisma.articleEvent.groupBy({ by: ["articleId"], where: { type: "DOWNLOAD" }, _count: { _all: true } });
  const ids = Array.from(new Set([...perArticle, ...perDownload].map((r) => r.articleId)));
  const arts = ids.length ? await prisma.article.findMany({ where: { id: { in: ids } }, select: { id: true, title: true, section: { select: { name: true } } } }) : [];
  const artMap = Object.fromEntries(arts.map((a) => [a.id, a]));

  const top = perArticle.map((r) => ({ title: artMap[r.articleId]?.title ?? "—", n: r._count._all })).sort((a, b) => b.n - a.n).slice(0, 8);
  const topMax = Math.max(1, ...top.map((t) => t.n));
  const topDl = perDownload.map((r) => ({ title: artMap[r.articleId]?.title ?? "—", n: r._count._all })).sort((a, b) => b.n - a.n).slice(0, 5);
  const dlMax = Math.max(1, ...topDl.map((t) => t.n));

  // per-section
  const secAgg: Record<string, number> = {};
  for (const r of perArticle) { const name = artMap[r.articleId]?.section?.name ?? "—"; secAgg[name] = (secAgg[name] ?? 0) + r._count._all; }
  const sections = Object.entries(secAgg).map(([label, n]) => ({ label, n })).sort((a, b) => b.n - a.n);
  const secMax = Math.max(1, ...sections.map((s) => s.n));

  // 14-day trend
  const recent = await prisma.articleEvent.findMany({ where: { type: "VIEW", createdAt: { gte: since14 } }, select: { createdAt: true } });
  const days: { label: string; n: number }[] = [];
  for (let i = 13; i >= 0; i--) {
    const d = new Date(now - i * 86400000);
    const key = d.toISOString().slice(0, 10);
    const n = recent.filter((e) => e.createdAt.toISOString().slice(0, 10) === key).length;
    days.push({ label: d.toLocaleDateString(undefined, { day: "numeric" }), n });
  }
  const dayMax = Math.max(1, ...days.map((d) => d.n));

  // device split
  const devRaw = await prisma.articleEvent.groupBy({ by: ["device"], where: { type: "VIEW" }, _count: { _all: true } });
  const devices = devRaw.map((d) => ({ label: d.device ?? "unknown", n: d._count._all })).sort((a, b) => b.n - a.n);
  const devTotal = Math.max(1, devices.reduce((s, d) => s + d.n, 0));

  const Stat = ({ n, label }: { n: number; label: string }) => (
    <div style={{ border: `1px solid ${T.rule}`, padding: "16px 18px" }}>
      <div style={{ fontFamily: T.serif, fontSize: 34, fontWeight: 600, lineHeight: 1 }}>{n.toLocaleString()}</div>
      <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted, marginTop: 6 }}>{label}</div>
    </div>
  );
  const Head = ({ children }: { children: React.ReactNode }) => (
    <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8, margin: "32px 0 12px" }}>{children}</h2>
  );
  const Bar = ({ label, n, max, right }: { label: string; n: number; max: number; right?: string }) => (
    <div style={{ padding: "9px 0", borderBottom: `1px solid ${T.rule}` }}>
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5, gap: 12 }}>
        <span style={{ fontFamily: T.serif, fontSize: 15 }}>{label}</span>
        <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>{right ?? n.toLocaleString()}</span>
      </div>
      <div style={{ height: 6, background: T.g200 }}><div style={{ height: "100%", width: `${Math.round((n / max) * 100)}%`, background: T.ink }} /></div>
    </div>
  );

  return (
    <main>
      <Link href="/dashboard" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Dashboard</Link>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 4px" }}>Readership analytics</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 20px" }}>Aggregate figures only — no individual reading histories.</p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12 }}>
        <Stat n={views} label="Total views" /><Stat n={views30} label="Views · 30 days" /><Stat n={downloads} label="PDF downloads" />
      </div>

      <Head>Views · last 14 days</Head>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 5, height: 120, borderBottom: `1px solid ${T.ink}`, paddingBottom: 0 }}>
        {days.map((d, i) => (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end", height: "100%" }}>
            <div title={`${d.n} views`} style={{ width: "100%", height: `${Math.round((d.n / dayMax) * 100)}%`, background: T.ink, minHeight: d.n ? 2 : 0 }} />
            <span style={{ fontFamily: T.sans, fontSize: 9.5, color: T.muted, marginTop: 4 }}>{d.label}</span>
          </div>
        ))}
      </div>

      <Head>Most read</Head>
      {top.length ? top.map((t, i) => <Bar key={i} label={t.title} n={t.n} max={topMax} />) : <p style={{ fontFamily: T.serif, color: T.muted }}>No views recorded yet.</p>}

      <Head>Views by section</Head>
      {sections.length ? sections.map((s, i) => <Bar key={i} label={s.label} n={s.n} max={secMax} />) : <p style={{ fontFamily: T.serif, color: T.muted }}>No data yet.</p>}

      <Head>Most downloaded</Head>
      {topDl.length ? topDl.map((t, i) => <Bar key={i} label={t.title} n={t.n} max={dlMax} />) : <p style={{ fontFamily: T.serif, color: T.muted }}>No downloads recorded yet.</p>}

      <Head>Device</Head>
      {devices.map((d, i) => <Bar key={i} label={d.label} n={d.n} max={devTotal} right={`${Math.round((d.n / devTotal) * 100)}%`} />)}

      <div style={{ display: "flex", gap: 10, alignItems: "flex-start", marginTop: 28, background: T.g50, border: `1px solid ${T.rule}`, padding: "14px 16px" }}>
        <IconInfo size={18} />
        <p style={{ fontFamily: T.sans, fontSize: 12.5, lineHeight: 1.55, color: T.muted, margin: 0 }}>
          Analytics are aggregate by design — a view/download count and a coarse device class, with no user identity, IP, or reading history, consistent with the Privacy Policy and India&rsquo;s DPDP Act.
        </p>
      </div>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Tracking + analytics written. Now run:  npm run build"
