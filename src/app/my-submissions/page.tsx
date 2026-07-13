import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { T, Eyebrow, Chip } from "@/lib/ui";
import { IconDoc } from "@/lib/icons";
import ResubmitForm from "./ResubmitForm";

export const dynamic = "force-dynamic";

const LABEL: Record<string, string> = { SUBMITTED: "Submitted", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", REVISION_REQUESTED: "Revision requested", PUBLISHED: "Published", REJECTED: "Rejected" };

export default async function MySubmissions() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const subs = await prisma.article.findMany({
    where: { submittedById: acc.id },
    include: { section: { select: { name: true } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>My submissions</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 16px" }}>My submissions</h1>
      {subs.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted }}>You haven&rsquo;t submitted any manuscripts yet.</p>
      ) : subs.map((a) => (
        <div key={a.id} style={{ borderTop: `1px solid ${T.rule}`, padding: "20px 0" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
            <Chip>{LABEL[a.status] ?? a.status}</Chip><span style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.section.name}</span>
          </div>
          <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 20, margin: "8px 0 4px" }}>{a.title}</h3>
          {a.status === "REVISION_REQUESTED" && (
            <div style={{ marginTop: 10 }}>
              <div style={{ background: "#fff8ec", border: "1px solid #e6c98a", padding: "12px 14px", marginBottom: 12 }}>
                <div style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", color: "#8a5a00", marginBottom: 4 }}>Editor feedback</div>
                <p style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.55, color: "#333", margin: 0 }}>{a.editorFeedback}</p>
              </div>
              <ResubmitForm article={{ id: a.id, title: a.title, abstract: a.abstract, bodyHtml: a.bodyHtml ?? "" }} />
            </div>
          )}
          {a.status === "PUBLISHED" && <a href={`/articles/${a.id}`} style={{ fontFamily: T.sans, fontSize: 13, textDecoration: "underline" }}>View published article →</a>}
        </div>
      ))}
    </main>
  );
}
