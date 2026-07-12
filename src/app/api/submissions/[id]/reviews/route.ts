import { prisma } from "@/lib/prisma";
import { getCurrentUser, isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!isStaff(user.role)) return forbidden();

  const { recommendation, comments } = (await req.json()) ?? {};
  const allowed = ["ACCEPT", "MINOR_REVISION", "MAJOR_REVISION", "REJECT"];
  if (!allowed.includes(recommendation))
    return Response.json({ error: "Invalid recommendation" }, { status: 400 });

  await prisma.review.upsert({
    where: { articleId_editorId: { articleId: id, editorId: user.id } },
    create: { articleId: id, editorId: user.id, recommendation, comments },
    update: { recommendation, comments },
  });
  await prisma.article.updateMany({
    where: { id, status: "SUBMITTED" }, data: { status: "UNDER_REVIEW" },
  });
  const reviews = await prisma.review.findMany({
    where: { articleId: id }, include: { editor: { select: { name: true } } },
  });
  return Response.json({ reviews });
}
