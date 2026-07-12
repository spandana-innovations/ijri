import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconDoc, IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<string, string> = {
  SUBMITTED: "New", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", PUBLISHED: "Published", REJECTED: "Rejected",
};

export default async function EditorQueue() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");

  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  const recent = await prisma.article.findMany({
    where: { status: { in: ["PUBLISHED", "REJECTED"] } },
    include: { section: { select: { name: true } } },
    orderBy: { decidedAt: "desc" }, take: 6,
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>Editorial Desk</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 4px" }}>Submission queue</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 8px" }}>
        Signed in as {acc.name} · {acc.role === "CHIEF_EDITOR" || acc.role === "ADMIN" ? "you can record reviews and publish decisions" : "you can record reviews"}
        {" · "}<Link href="/admin" style={{ textDecoration: "underline" }}>Admin</Link>
      </p>

      {queue.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted, marginTop: 20 }}>No manuscripts are awaiting action.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.ink}`, marginTop: 14 }}>
          {queue.map((a) => (
            <Link key={a.id} href={`/editor/${a.id}`} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 12, alignItems: "center", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div>
                <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 18, lineHeight: 1.25 }}>{a.title}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{a.section.name} · by {a.submittedBy.name} · {a.reviews.length} review(s)</div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.paper, background: a.status === "SUBMITTED" ? "#b26a00" : T.ink, padding: "3px 8px" }}>{STATUS_LABEL[a.status]}</span>
                <IconArrow size={16} />
              </div>
            </Link>
          ))}
        </div>
      )}

      {recent.length > 0 && (
        <>
          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, margin: "40px 0 0", borderBottom: `1px solid ${T.rule}`, paddingBottom: 8 }}>Recent decisions</h2>
          {recent.map((a) => (
            <div key={a.id} style={{ display: "flex", justifyContent: "space-between", padding: "11px 4px", borderBottom: `1px solid ${T.rule}`, fontFamily: T.sans, fontSize: 13 }}>
              <span style={{ color: T.ink }}>{a.title}</span>
              <span style={{ color: a.status === "PUBLISHED" ? "#1a7f37" : "#b00020", textTransform: "uppercase", fontSize: 11, letterSpacing: "0.06em" }}>{STATUS_LABEL[a.status]}</span>
            </div>
          ))}
        </>
      )}
    </main>
  );
}
