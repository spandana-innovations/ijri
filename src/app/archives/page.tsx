import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Archives() {
  const issues = await prisma.issue.findMany({
    orderBy: [{ volume: "desc" }, { number: "desc" }],
    include: {
      articles: { where: { status: "PUBLISHED" }, include: { section: true }, orderBy: { startPage: "asc" } },
    },
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Archives</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 24px" }}>Archives</h1>
      {issues.map((iss) => (
        <div key={iss.id} style={{ border: `1px solid ${T.ink}`, marginBottom: 24 }}>
          <div style={{ background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600, padding: "10px 16px" }}>
            IJRI · Volume {iss.volume}, Issue {iss.number} · {iss.label}
          </div>
          {iss.articles.map((a, i) => (
            <div key={a.id} style={{ display: "grid", gridTemplateColumns: "30px 1fr auto", gap: 12, padding: "14px 16px", borderTop: i === 0 ? "none" : `1px solid ${T.rule}` }}>
              <div style={{ fontFamily: T.serif, fontSize: 16, color: T.muted }}>{i + 1}.</div>
              <div>
                <Link href={`/articles/${a.id}`}><span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.3 }}>{a.title}</span></Link>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{a.authorNames} · {a.section.name} · pp. {pages(a)}</div>
              </div>
              <Link href={`/articles/${a.id}`} style={{ fontFamily: T.sans, fontSize: 11.5, textDecoration: "underline", textUnderlineOffset: 2, whiteSpace: "nowrap" }}>Read</Link>
            </div>
          ))}
        </div>
      ))}
    </main>
  );
}
