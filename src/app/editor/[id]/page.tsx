import { redirect, notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";
import ReviewDesk from "./ReviewDesk";

export const dynamic = "force-dynamic";

export default async function SubmissionDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");

  const a = await prisma.article.findUnique({
    where: { id },
    include: {
      section: { select: { name: true } }, issue: { select: { id: true } },
      submittedBy: { select: { name: true, email: true, affiliation: true } },
      reviews: { include: { editor: { select: { id: true, name: true } } }, orderBy: { createdAt: "asc" } },
    },
  });
  if (!a) notFound();
  const issues = await prisma.issue.findMany({ orderBy: [{ volume: "desc" }, { number: "desc" }], select: { id: true, volume: true, number: true, label: true, isCurrent: true } });

  const article = {
    id: a.id, title: a.title, abstract: a.abstract, bodyHtml: sanitize(a.bodyHtml ?? ""), authorNames: a.authorNames,
    affiliation: a.affiliation, status: a.status, section: a.section.name, submittedBy: a.submittedBy,
    issueId: a.issue?.id ?? null, startPage: a.startPage, endPage: a.endPage, revisionCount: a.revisionCount,
    reviews: a.reviews.map((r) => ({ id: r.id, editorId: r.editor.id, editorName: r.editor.name, recommendation: r.recommendation, comments: r.comments })),
  };
  const myReview = article.reviews.find((r) => r.editorId === acc.id) ?? null;

  return <ReviewDesk me={{ id: acc.id, role: acc.role }} article={article} issues={issues} myRecommendation={myReview?.recommendation ?? null} myComments={myReview?.comments ?? ""} />;
}
