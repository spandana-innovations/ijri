#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#11) archives with sorting: by Issue (default), by Year, by Date.
# Run in repo:  bash build-archives.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Archives with sort..."
mkdir -p src/app/archives

cat > src/app/archives/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";
import { IconArchive } from "@/lib/icons";

export const dynamic = "force-dynamic";

type Sort = "issue" | "year" | "date";
const yearOf = (d: Date | null, label: string) => (d ? new Date(d).getFullYear() : (label.match(/\b(20\d{2})\b/)?.[1] ? Number(label.match(/\b(20\d{2})\b/)![1]) : 0));

function ArticleRow({ a }: { a: { id: string; title: string; authorNames: string; startPage: number | null; endPage: number | null; section: { name: string } } }) {
  return (
    <Link href={`/articles/${a.id}`} style={{ display: "block", padding: "14px 0", borderBottom: `1px solid ${T.rule}` }}>
      <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.07em", textTransform: "uppercase", color: T.muted }}>{a.section.name}{a.startPage ? ` · pp. ${a.startPage}\u2013${a.endPage ?? a.startPage}` : ""}</div>
      <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 19, lineHeight: 1.25, margin: "3px 0 2px" }}>{a.title}</div>
      <div style={{ fontFamily: T.sans, fontSize: 13, color: T.ink }}>{a.authorNames}</div>
    </Link>
  );
}

export default async function Archives({ searchParams }: { searchParams: Promise<{ sort?: string }> }) {
  const sp = await searchParams;
  const sort: Sort = sp.sort === "year" || sp.sort === "date" ? sp.sort : "issue";

  const tabs: [Sort, string][] = [["issue", "By issue"], ["year", "By year"], ["date", "By date"]];

  const Header = (
    <>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconArchive size={22} /><Eyebrow inverse>Archives</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 14px" }}>Archives</h1>
      <div style={{ display: "flex", gap: 8, borderBottom: `1px solid ${T.ink}`, marginBottom: 22 }}>
        {tabs.map(([key, label]) => (
          <Link key={key} href={`/archives?sort=${key}`} style={{ fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.04em", textTransform: "uppercase", padding: "9px 14px", background: sort === key ? T.ink : "transparent", color: sort === key ? T.paper : T.ink }}>{label}</Link>
        ))}
      </div>
    </>
  );

  if (sort === "date") {
    const arts = await prisma.article.findMany({ where: { status: "PUBLISHED" }, orderBy: { publishedAt: "desc" }, include: { section: { select: { name: true } } } });
    return (
      <main style={{ maxWidth: 820, margin: "0 auto", padding: "40px 20px" }}>
        {Header}
        {arts.length === 0 ? <p style={{ fontFamily: T.serif, color: T.muted }}>No published articles yet.</p> : arts.map((a) => <ArticleRow key={a.id} a={a} />)}
      </main>
    );
  }

  // issue / year both group by issue
  const issues = await prisma.issue.findMany({
    orderBy: [{ volume: "desc" }, { number: "desc" }],
    include: { articles: { where: { status: "PUBLISHED" }, orderBy: { startPage: "asc" }, include: { section: { select: { name: true } } } } },
  });
  const withArticles = issues.filter((i) => i.articles.length > 0);

  const IssueBlock = (i: (typeof withArticles)[number]) => (
    <section key={i.id} style={{ marginBottom: 30 }}>
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", borderBottom: `2px solid ${T.ink}`, paddingBottom: 8, marginBottom: 8 }}>
        <h2 style={{ fontFamily: T.serif, fontSize: 24, margin: 0 }}>Volume {i.volume}, Issue {i.number}</h2>
        <span style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>{i.label}{i.isCurrent ? " · current" : ""}</span>
      </div>
      {i.articles.map((a) => <ArticleRow key={a.id} a={a} />)}
    </section>
  );

  if (sort === "year") {
    const byYear = new Map<number, typeof withArticles>();
    for (const i of withArticles) { const y = yearOf(i.publishedAt, i.label); if (!byYear.has(y)) byYear.set(y, []); byYear.get(y)!.push(i); }
    const years = Array.from(byYear.keys()).sort((a, b) => b - a);
    return (
      <main style={{ maxWidth: 820, margin: "0 auto", padding: "40px 20px" }}>
        {Header}
        {years.map((y) => (
          <div key={y} style={{ marginBottom: 20 }}>
            <div style={{ fontFamily: T.serif, fontSize: 30, fontWeight: 600, color: T.ink, margin: "6px 0 12px" }}>{y || "Undated"}</div>
            {byYear.get(y)!.map((i) => IssueBlock(i))}
          </div>
        ))}
      </main>
    );
  }

  return (
    <main style={{ maxWidth: 820, margin: "0 auto", padding: "40px 20px" }}>
      {Header}
      {withArticles.length === 0 ? <p style={{ fontFamily: T.serif, color: T.muted }}>No published issues yet.</p> : withArticles.map((i) => IssueBlock(i))}
    </main>
  );
}
IJRI_EOF

echo ""
echo "Archives written. Now run:  npm run build"
