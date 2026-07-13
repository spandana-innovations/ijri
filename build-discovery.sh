#!/usr/bin/env bash
# ==========================================================================
# IJRI — discovery & SEO (all NEW files; nothing existing is rewritten):
#   /search        — full-text-ish search over title / abstract / authors
#   /sitemap.xml   — via app/sitemap.ts (Next convention)
#   /robots.txt    — via app/robots.ts
#   /feed.xml      — RSS of the 30 most recent published articles
# Run in repo:  bash build-discovery.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Discovery + SEO..."
mkdir -p src/app/search "src/app/feed.xml"

# ---------------------------------------------------------------- search page
cat > src/app/search/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";
import { IconInfo } from "@/lib/icons";
import SearchBox from "./SearchBox";

export const dynamic = "force-dynamic";

export default async function Search({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q } = await searchParams;
  const query = (q ?? "").trim();

  const results = query
    ? await prisma.article.findMany({
        where: {
          status: "PUBLISHED",
          OR: [
            { title: { contains: query, mode: "insensitive" } },
            { abstract: { contains: query, mode: "insensitive" } },
            { authorNames: { contains: query, mode: "insensitive" } },
          ],
        },
        include: { section: { select: { name: true } }, issue: { select: { volume: true, number: true } } },
        orderBy: { publishedAt: "desc" }, take: 40,
      })
    : [];

  return (
    <main style={{ maxWidth: 780, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Search</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 16px" }}>Search the journal</h1>
      <SearchBox initial={query} />

      {query && (
        <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "18px 0 8px" }}>
          {results.length} result{results.length === 1 ? "" : "s"} for &ldquo;{query}&rdquo;
        </p>
      )}

      {query && results.length === 0 && (
        <div style={{ display: "flex", gap: 9, alignItems: "flex-start", marginTop: 12, background: T.g50, border: `1px solid ${T.rule}`, padding: "14px 16px" }}>
          <IconInfo size={18} />
          <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: 0 }}>No published articles matched. Try an author name, a keyword from the title, or a broader term.</p>
        </div>
      )}

      <div style={{ marginTop: 10 }}>
        {results.map((a) => (
          <Link key={a.id} href={`/articles/${a.id}`} style={{ display: "block", padding: "18px 0", borderTop: `1px solid ${T.rule}` }}>
            <div style={{ fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>
              {a.section.name}{a.issue ? ` · Vol ${a.issue.volume}, Issue ${a.issue.number}` : ""}
            </div>
            <h3 className="cardtitle" style={{ fontFamily: T.serif, fontSize: 20, margin: "4px 0 5px", lineHeight: 1.25 }}>{a.title}</h3>
            <div style={{ fontFamily: T.sans, fontSize: 13, color: T.ink, marginBottom: 5 }}>{a.authorNames}</div>
            <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.5, color: "#444", margin: 0 }}>{a.abstract.length > 220 ? a.abstract.slice(0, 220) + "…" : a.abstract}</p>
          </Link>
        ))}
      </div>
    </main>
  );
}
IJRI_EOF

cat > src/app/search/SearchBox.tsx << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T } from "@/lib/ui";

export default function SearchBox({ initial }: { initial: string }) {
  const [q, setQ] = useState(initial);
  const router = useRouter();
  return (
    <form onSubmit={(e) => { e.preventDefault(); router.push(`/search?q=${encodeURIComponent(q.trim())}`); }} style={{ display: "flex", gap: 10 }}>
      <input value={q} onChange={(e) => setQ(e.target.value)} autoFocus placeholder="Search articles, authors, keywords…"
        style={{ flex: 1, fontFamily: T.sans, fontSize: 15, padding: "12px 14px", border: `1px solid ${T.ink}`, background: T.paper }} />
      <button type="submit" style={{ padding: "12px 22px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Search</button>
    </form>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- sitemap.xml (Next convention)
cat > src/app/sitemap.ts << 'IJRI_EOF'
import type { MetadataRoute } from "next";
import { prisma } from "@/lib/prisma";

const BASE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://ijrein.org";
export const dynamic = "force-dynamic";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [articles, sections] = await Promise.all([
    prisma.article.findMany({ where: { status: "PUBLISHED" }, select: { id: true, publishedAt: true } }),
    prisma.section.findMany({ select: { slug: true } }),
  ]);

  const staticPages = ["", "/archives", "/sections", "/editorial-board", "/for-authors", "/about", "/aims-scope", "/ethics", "/privacy", "/terms", "/copyright", "/refunds", "/contact", "/subscribe", "/search"];

  return [
    ...staticPages.map((p) => ({ url: `${BASE}${p}`, changeFrequency: "weekly" as const, priority: p === "" ? 1 : 0.6 })),
    ...sections.map((s) => ({ url: `${BASE}/sections/${s.slug}`, changeFrequency: "weekly" as const, priority: 0.6 })),
    ...articles.map((a) => ({ url: `${BASE}/articles/${a.id}`, lastModified: a.publishedAt ?? undefined, changeFrequency: "monthly" as const, priority: 0.8 })),
  ];
}
IJRI_EOF

# ---------------------------------------------------------------- robots.txt (Next convention)
cat > src/app/robots.ts << 'IJRI_EOF'
import type { MetadataRoute } from "next";

const BASE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://ijrein.org";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/", disallow: ["/admin", "/editor", "/api", "/my-submissions", "/submit"] }],
    sitemap: `${BASE}/sitemap.xml`,
  };
}
IJRI_EOF

# ---------------------------------------------------------------- RSS feed
cat > "src/app/feed.xml/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";

const BASE = process.env.NEXT_PUBLIC_SITE_URL ?? "https://ijrein.org";
export const dynamic = "force-dynamic";

function esc(s: string) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

export async function GET() {
  const arts = await prisma.article.findMany({
    where: { status: "PUBLISHED" }, orderBy: { publishedAt: "desc" }, take: 30,
    include: { section: { select: { name: true } } },
  });

  const items = arts.map((a) =>
    `<item>` +
    `<title>${esc(a.title)}</title>` +
    `<link>${BASE}/articles/${a.id}</link>` +
    `<guid isPermaLink="true">${BASE}/articles/${a.id}</guid>` +
    `<category>${esc(a.section.name)}</category>` +
    `<description>${esc(a.abstract)}</description>` +
    (a.publishedAt ? `<pubDate>${new Date(a.publishedAt).toUTCString()}</pubDate>` : "") +
    `</item>`
  ).join("");

  const xml =
    `<?xml version="1.0" encoding="UTF-8"?>` +
    `<rss version="2.0"><channel>` +
    `<title>International Journal of Research and Innovation</title>` +
    `<link>${BASE}</link>` +
    `<description>Latest published articles from IJRI</description>` +
    `<language>en</language>` +
    items +
    `</channel></rss>`;

  return new Response(xml, { headers: { "Content-Type": "application/xml; charset=utf-8" } });
}
IJRI_EOF

echo ""
echo "Discovery + SEO written. Now run:  npm run build"
echo "Add a 'Search' link to your nav when convenient (or ask Claude Code to)."
