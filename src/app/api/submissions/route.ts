import { prisma } from "@/lib/prisma";
import { getCurrentUser, isStaff, unauthorized } from "@/lib/auth";

export async function POST(req: Request) {
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  const b = await req.json();
  const { title, abstract, bodyHtml, authorNames, affiliation, sectionId } = b ?? {};
  if (!title || !abstract || !bodyHtml || !sectionId)
    return Response.json({ error: "Missing required fields" }, { status: 400 });

  const article = await prisma.article.create({
    data: {
      title, abstract, bodyHtml,
      authorNames: authorNames ?? user.name, affiliation, sectionId,
      status: "SUBMITTED", submittedById: user.id,
    },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}

export async function GET(req: Request) {
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!isStaff(user.role)) return Response.json({ error: "Not permitted" }, { status: 403 });
  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, reviews: { include: { editor: { select: { name: true } } } } },
    orderBy: { createdAt: "asc" },
  });
  return Response.json(queue);
}
