import { prisma } from "@/lib/prisma";
import { getCurrentUser, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (user.role !== "CHIEF_EDITOR" && user.role !== "ADMIN")
    return forbidden("Only the Editor-in-Chief can publish");

  const { decision } = (await req.json()) ?? {};

  if (decision === "REJECT") {
    const a = await prisma.article.update({
      where: { id },
      data: { status: "REJECTED", chiefEditorId: user.id, decidedAt: new Date() },
      select: { id: true, status: true },
    });
    return Response.json(a);
  }
  if (decision === "PUBLISH") {
    const reviewCount = await prisma.review.count({ where: { articleId: id } });
    if (reviewCount === 0)
      return Response.json({ error: "No editorial review on record" }, { status: 409 });
    const current = await prisma.issue.findFirst({ where: { isCurrent: true }, select: { id: true } });
    const a = await prisma.article.update({
      where: { id },
      data: {
        status: "PUBLISHED", issueId: current?.id ?? null,
        chiefEditorId: user.id, decidedAt: new Date(), publishedAt: new Date(),
      },
      select: { id: true, status: true, issueId: true },
    });
    return Response.json(a);
  }
  return Response.json({ error: "Unknown decision" }, { status: 400 });
}
