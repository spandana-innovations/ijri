import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const article = await prisma.article.findUnique({ where: { id }, select: { submittedById: true, status: true, title: true, abstract: true, bodyHtml: true } });
  if (!article) return Response.json({ error: "Not found" }, { status: 404 });
  if (article.submittedById !== acc.id) return forbidden("You can only revise your own submissions");
  if (article.status !== "REVISION_REQUESTED") return Response.json({ error: "This submission is not open for revision" }, { status: 409 });

  const b = await req.json().catch(() => null);
  const { title, abstract, bodyHtml } = b ?? {};
  if (!title || !abstract || !bodyHtml) return Response.json({ error: "Missing required fields" }, { status: 400 });

  // snapshot the version that is about to be replaced (the "before")
  await prisma.articleRevision.create({
    data: { articleId: id, title: article.title, abstract: article.abstract, bodyHtml: article.bodyHtml, editedByName: acc.name },
  });

  const updated = await prisma.article.update({
    where: { id },
    data: { title, abstract, bodyHtml, status: "SUBMITTED", revisionCount: { increment: 1 } },
    select: { id: true, status: true },
  });
  return Response.json(updated);
}
