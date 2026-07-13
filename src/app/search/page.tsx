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
