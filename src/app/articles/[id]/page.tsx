import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";
import { sanitize } from "@/lib/sanitize";
import { T, Eyebrow, Chip, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function ArticlePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    include: {
      section: true, issue: true,
      reviews: { include: { editor: { select: { name: true } } } },
      chiefEditor: { select: { name: true } },
    },
  });
  if (!article) notFound();

  const user = await getCurrentUser();
  const unlocked = await canReadArticle(user, article);

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "32px 20px 40px" }}>
      <Link href="/" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Back to issue</Link>
      <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted, margin: "18px 0 12px", lineHeight: 1.5 }}>
        International Journal of Research and Innovation<br />
        Vol {article.issue?.volume}, Issue {article.issue?.number} ({article.issue?.label}), pp. {pages(article)}
      </div>
      <Eyebrow inverse>{article.section.name}</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, lineHeight: 1.1, fontSize: "clamp(28px,5vw,42px)", margin: "16px 0 18px" }}>{article.title}</h1>
      <div style={{ fontFamily: T.sans, fontSize: 14, borderTop: `1px solid ${T.rule}`, borderBottom: `1px solid ${T.rule}`, padding: "12px 0" }}>
        <strong style={{ fontWeight: 600 }}>{article.authorNames}</strong><span style={{ color: T.muted }}> · {article.affiliation}</span>
      </div>

      <div style={{ background: T.faint, borderLeft: `3px solid ${T.ink}`, padding: "16px 20px", margin: "26px 0" }}>
        <Eyebrow>Abstract</Eyebrow>
        <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.55, color: "#222", margin: "8px 0 0" }}>{article.abstract}</p>
      </div>

      {unlocked ? (
        <div className="body" dangerouslySetInnerHTML={{ __html: sanitize(article.bodyHtml ?? "") }} />
      ) : (
        <section style={{ border: `1px solid ${T.ink}`, padding: "22px 20px", margin: "10px 0 20px", background: T.faint }}>
          <Eyebrow inverse>Subscribers only</Eyebrow>
          <h3 style={{ fontFamily: T.serif, fontSize: 22, margin: "12px 0 6px" }}>Continue reading the full article</h3>
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, lineHeight: 1.6, margin: 0 }}>
            The abstract is free. Full text and PDF download require a subscription. {user ? "" : "Sign in or subscribe to continue."}
          </p>
        </section>
      )}

      <section style={{ marginTop: 30, border: `1px solid ${T.ink}`, padding: "18px 20px" }}>
        <Eyebrow>Peer review</Eyebrow>
        <p style={{ fontFamily: T.sans, fontSize: 13, margin: "10px 0 8px", lineHeight: 1.6 }}>Reviewed under double-blind evaluation by {article.reviews.length} members of the editorial board:</p>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {article.reviews.map((r) => <Chip key={r.id}>{r.editor.name}</Chip>)}
        </div>
        {article.chiefEditor && <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, borderTop: `1px solid ${T.rule}`, marginTop: 12, paddingTop: 10 }}>Accepted and published by <strong style={{ color: T.ink }}>{article.chiefEditor.name}</strong>, Editor-in-Chief.</div>}
      </section>
    </main>
  );
}
