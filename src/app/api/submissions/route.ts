import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!acc.approved && !isStaff(acc.role)) return forbidden("Your account is awaiting approval");

  const b = await req.json().catch(() => null);
  const { title, abstract, bodyHtml, authorNames, affiliation, sectionId } = b ?? {};
  if (!title || !abstract || !bodyHtml || !sectionId)
    return Response.json({ error: "Missing required fields" }, { status: 400 });

  const article = await prisma.article.create({
    data: {
      title, abstract, bodyHtml,
      authorNames: authorNames ?? acc.name, affiliation, sectionId,
      status: "SUBMITTED", submittedById: acc.id,
    },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  return Response.json(queue);
}
