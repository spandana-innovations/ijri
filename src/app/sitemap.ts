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
