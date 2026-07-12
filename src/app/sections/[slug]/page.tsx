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
