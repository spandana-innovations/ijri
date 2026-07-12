import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Home() {
  const articles = await prisma.article.findMany({
    where: { status: "PUBLISHED" },
    include: { section: true },
    orderBy: { startPage: "asc" },
  });

  if (articles.length === 0) {
    return <main style={{ maxWidth: 680, margin: "60px auto", padding: "0 20px", fontFamily: T.serif }}><p>No articles have been published yet.</p></main>;
  }

  const [lead, ...rest] = articles;

  return (
    <main style={{ maxWidth: 1120, margin: "0 auto", padding: "32px 20px 40px" }}>
      <section className="leadgrid" style={{ display: "grid", gridTemplateColumns: "minmax(0,2fr) 1px minmax(0,1fr)", gap: 32, alignItems: "start", paddingBottom: 32, borderBottom: `1px solid ${T.ink}` }}>
        <Link href={`/articles/${lead.id}`}>
          <Eyebrow inverse>From the current issue</Eyebrow>
          <h1 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, lineHeight: 1.08, fontSize: "clamp(27px,4.4vw,44px)", margin: "14px 0" }}>{lead.title}</h1>
          <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.5, color: "#2a2a2a", margin: "0 0 12px" }}>{lead.abstract}</p>
          <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>{lead.authorNames} · {lead.affiliation}</div>
        </Link>
        <div style={{ background: T.rule, width: 1, height: "100%" }} />
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <Eyebrow>Also in this issue</Eyebrow>
          {rest.slice(0, 3).map((a, i) => (
            <Link key={a.id} href={`/articles/${a.id}`} style={{ paddingTop: i === 0 ? 4 : 16, borderTop: i === 0 ? "none" : `1px solid ${T.rule}` }}>
              <Eyebrow>{a.section.name}</Eyebrow>
              <h3 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 18, lineHeight: 1.2, margin: "6px 0 4px" }}>{a.title}</h3>
              <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.authorNames}</div>
            </Link>
          ))}
        </div>
      </section>

      <section className="cardgrid" style={{ display: "grid", gridTemplateColumns: "repeat(3,minmax(0,1fr))", gap: "32px 30px", marginTop: 32 }}>
        {rest.slice(3).map((a) => (
          <Link key={a.id} href={`/articles/${a.id}`}>
            <Eyebrow>{a.section.name}</Eyebrow>
            <h3 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 21, lineHeight: 1.2, margin: "8px 0 6px" }}>{a.title}</h3>
            <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.5, color: "#333", margin: "0 0 8px" }}>{a.abstract}</p>
            <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.authorNames} · pp. {pages(a)}</div>
          </Link>
        ))}
      </section>
    </main>
  );
}
