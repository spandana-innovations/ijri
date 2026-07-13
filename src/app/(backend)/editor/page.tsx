import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconDoc, IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<string, string> = { SUBMITTED: "New", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", REVISION_REQUESTED: "Revision", PUBLISHED: "Published", REJECTED: "Rejected" };

export default async function EditorQueue() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/dashboard");

  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED", "REVISION_REQUESTED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } }, assignments: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  const recent = await prisma.article.findMany({
    where: { status: { in: ["PUBLISHED", "REJECTED"] } },
    orderBy: { decidedAt: "desc" },
    take: 10,
    include: {
      submittedBy: { select: { name: true } },
      chiefEditor: { select: { name: true } },
      reviews: { include: { editor: { select: { name: true } } } },
    },
  });

  const fmt = (d: Date) => new Date(d).toLocaleString(undefined, { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
  const fmtD = (d: Date | null) => (d ? new Date(d).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" }) : "—");

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>Editorial Desk</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 4px" }}>Submission queue</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 16px" }}>Signed in as {acc.name}</p>

      {queue.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted }}>No manuscripts are awaiting action.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.ink}` }}>
          {queue.map((a) => (
            <Link key={a.id} href={`/editor/${a.id}`} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 12, alignItems: "center", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ minWidth: 0 }}>
                <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 18, lineHeight: 1.25 }}>{a.title}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.ink, marginTop: 3 }}>{a.authorNames}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 2 }}>
                  {a.section.name} · submitted {fmt(a.createdAt)} by {a.submittedBy.name} · {a.assignments.length} editor{a.assignments.length === 1 ? "" : "s"} · {a.reviews.length} review{a.reviews.length === 1 ? "" : "s"}
                </div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.05em", textTransform: "uppercase", color: T.paper, background: a.status === "SUBMITTED" ? "#b26a00" : T.ink, padding: "3px 8px", whiteSpace: "nowrap" }}>{STATUS_LABEL[a.status]}</span>
                <IconArrow size={16} />
              </div>
            </Link>
          ))}
        </div>
      )}

      {recent.length > 0 && (
        <>
          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, margin: "34px 0 0", borderBottom: `1px solid ${T.rule}`, paddingBottom: 8 }}>Recent decisions</h2>
          {recent.map((a) => (
            <Link key={a.id} href={`/editor/${a.id}`} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 12, alignItems: "center", padding: "13px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ minWidth: 0 }}>
                <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.3 }}>{a.title}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 2 }}>
                  by {a.authorNames} · submitted by {a.submittedBy.name}
                  {a.reviews.length > 0 ? ` · reviewed by ${a.reviews.map((r) => r.editor.name).join(", ")}` : " · no reviews on record"}
                  {a.chiefEditor ? ` · decided by ${a.chiefEditor.name}` : ""} · {a.status === "PUBLISHED" ? "published" : "decided"} {fmtD(a.publishedAt ?? a.decidedAt)}
                </div>
              </div>
              <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.05em", textTransform: "uppercase", color: a.status === "PUBLISHED" ? "#1a7f37" : "#b00020", whiteSpace: "nowrap" }}>{STATUS_LABEL[a.status]}</span>
            </Link>
          ))}
        </>
      )}
    </main>
  );
}
