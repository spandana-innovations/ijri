import { prisma } from "@/lib/prisma";
import { getCurrentUser, isStaff, unauthorized, forbidden } from "@/lib/auth";

const VALID = ["ACCEPT", "MINOR_REVISION", "MAJOR_REVISION", "REJECT"];

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!isStaff(user.role)) return forbidden();

  const body = await req.json().catch(() => null);
  const recommendation = String(body?.recommendation ?? "");
  const comments = body?.comments ? String(body.comments) : null;
  if (!VALID.includes(recommendation)) return Response.json({ error: "Invalid recommendation" }, { status: 400 });

  const review = await prisma.review.upsert({
    where: { articleId_editorId: { articleId: id, editorId: user.id } },
    update: { recommendation: recommendation as never, comments },
    create: { articleId: id, editorId: user.id, recommendation: recommendation as never, comments },
  });
  await prisma.article.update({ where: { id }, data: { status: "UNDER_REVIEW" } });
  return Response.json(review, { status: 201 });
}
