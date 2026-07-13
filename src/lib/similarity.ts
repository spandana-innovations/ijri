import { prisma } from "./prisma";

function normalize(s: string): string {
  return s.replace(/<[^>]+>/g, " ").replace(/&[a-z]+;/gi, " ").toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
}
function shingles(text: string, k = 5): Set<string> {
  const words = text.split(" ").filter(Boolean);
  const set = new Set<string>();
  for (let i = 0; i + k <= words.length; i++) set.add(words.slice(i, i + k).join(" "));
  return set;
}
function containment(target: Set<string>, other: Set<string>): number {
  if (target.size === 0) return 0;
  let inter = 0;
  for (const x of target) if (other.has(x)) inter++;
  return inter / target.size;
}

export type SimMatch = { articleId: string; title: string; score: number };

export async function computeSimilarity(id: string): Promise<{ score: number; matches: SimMatch[] } | null> {
  const target = await prisma.article.findUnique({ where: { id }, select: { id: true, title: true, abstract: true, bodyHtml: true } });
  if (!target) return null;
  const others = await prisma.article.findMany({ where: { id: { not: id } }, select: { id: true, title: true, abstract: true, bodyHtml: true } });
  const tSh = shingles(normalize(`${target.title} ${target.abstract} ${target.bodyHtml ?? ""}`));
  const matches: SimMatch[] = [];
  for (const o of others) {
    const oSh = shingles(normalize(`${o.title} ${o.abstract} ${o.bodyHtml ?? ""}`));
    const score = Math.round(containment(tSh, oSh) * 100);
    if (score > 0) matches.push({ articleId: o.id, title: o.title, score });
  }
  matches.sort((a, b) => b.score - a.score);
  return { score: matches[0]?.score ?? 0, matches: matches.slice(0, 5) };
}
