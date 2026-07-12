import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    include: {
      section: true, issue: true,
      reviews: { include: { editor: { select: { name: true } } } },
      chiefEditor: { select: { name: true } },
    },
  });
  if (!article) return Response.json({ error: "Not found" }, { status: 404 });

  const user = await getCurrentUser(req);
  const unlocked = await canReadArticle(user, article);

  const payload = {
    id: article.id, title: article.title, abstract: article.abstract,
    authorNames: article.authorNames, affiliation: article.affiliation,
    section: article.section.name, volume: article.issue?.volume, issue: article.issue?.number,
    pages: article.startPage && article.endPage ? `${article.startPage}-${article.endPage}` : null,
    doi: article.doi, reviewers: article.reviews.map((r) => r.editor.name),
    chiefEditor: article.chiefEditor?.name ?? null, locked: !unlocked,
  };
  if (!unlocked) return Response.json(payload);
  return Response.json({ ...payload, bodyHtml: article.bodyHtml });
}
