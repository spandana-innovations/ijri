import Link from "next/link";
import { redirect, notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";
import { T, Eyebrow, Chip } from "@/lib/ui";
import { IconArchive } from "@/lib/icons";

export const dynamic = "force-dynamic";

function Version({ tag, when, who, title, abstract, bodyHtml, open }: { tag: string; when: string; who?: string; title: string; abstract: string; bodyHtml: string; open?: boolean }) {
  return (
    <details open={open} style={{ border: `1px solid ${T.rule}`, marginBottom: 12 }}>
      <summary style={{ cursor: "pointer", padding: "12px 16px", background: T.g50, fontFamily: T.sans, fontSize: 13, display: "flex", gap: 10, alignItems: "center" }}>
        <Chip>{tag}</Chip><strong style={{ fontFamily: T.serif, fontSize: 16 }}>{title}</strong>
        <span style={{ marginLeft: "auto", color: T.muted, fontSize: 12 }}>{when}{who ? ` · ${who}` : ""}</span>
      </summary>
      <div style={{ padding: "14px 18px" }}>
        <Eyebrow>Abstract</Eyebrow>
        <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.55, color: "#333", margin: "6px 0 14px" }}>{abstract}</p>
        <Eyebrow>Body</Eyebrow>
        <div className="body" style={{ marginTop: 6 }} dangerouslySetInnerHTML={{ __html: bodyHtml }} />
      </div>
    </details>
  );
}

export default async function History({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount();
  if (!acc) redirect("/login");

  const art = await prisma.article.findUnique({ where: { id }, select: { id: true, title: true, abstract: true, bodyHtml: true, submittedById: true, revisionCount: true, createdAt: true } });
  if (!art) notFound();
  if (art.submittedById !== acc.id && !isStaff(acc.role)) redirect("/dashboard");

  const revisions = await prisma.articleRevision.findMany({ where: { articleId: id }, orderBy: { createdAt: "desc" } });

  return (
    <main style={{ maxWidth: 800, margin: "0 auto", padding: "36px 20px 56px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconArchive size={22} /><Eyebrow inverse>Edit history</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,32px)", margin: "10px 0 6px" }}>{art.title}</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 20px" }}>
        {revisions.length === 0 ? "No edits recorded yet — this is the original submission." : `${revisions.length} earlier version${revisions.length === 1 ? "" : "s"} recorded. Newest first.`}
      </p>

      <Version tag="Current" when="latest" title={art.title} abstract={art.abstract} bodyHtml={sanitize(art.bodyHtml ?? "")} open />
      {revisions.map((r) => (
        <Version key={r.id} tag="Before edit" when={new Date(r.createdAt).toLocaleString()} who={r.editedByName} title={r.title} abstract={r.abstract} bodyHtml={sanitize(r.bodyHtml ?? "")} />
      ))}
    </main>
  );
}
