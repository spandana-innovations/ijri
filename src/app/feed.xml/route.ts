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
