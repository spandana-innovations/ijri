import { prisma } from "@/lib/prisma";
import { getCurrentUser, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (user.role !== "CHIEF_EDITOR" && user.role !== "ADMIN") return forbidden("Only the Editor-in-Chief can decide");

  const body = await req.json().catch(() => null);
  const decision = String(body?.decision ?? "");

  if (decision === "PUBLISH") {
    const article = await prisma.article.update({
      where: { id },
      data: {
        status: "PUBLISHED", chiefEditorId: user.id, decidedAt: new Date(), publishedAt: new Date(),
        issueId: body?.issueId ?? undefined, startPage: body?.startPage ?? undefined, endPage: body?.endPage ?? undefined,
      }, select: { id: true, status: true },
    });
    return Response.json(article);
  }
  if (decision === "REJECT") {
    const article = await prisma.article.update({ where: { id }, data: { status: "REJECTED", chiefEditorId: user.id, decidedAt: new Date() }, select: { id: true, status: true } });
    return Response.json(article);
  }
  if (decision === "REVISE") {
    const feedback = String(body?.feedback ?? "").trim();
    if (!feedback) return Response.json({ error: "Feedback to the author is required" }, { status: 400 });
    const article = await prisma.article.update({ where: { id }, data: { status: "REVISION_REQUESTED", editorFeedback: feedback }, select: { id: true, status: true } });
    return Response.json(article);
  }
  return Response.json({ error: "Invalid decision" }, { status: 400 });
}
