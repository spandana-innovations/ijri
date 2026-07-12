import { prisma } from "@/lib/prisma";
import { getCurrentUser, unauthorized, forbidden } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";
import { signedPdfUrl } from "@/lib/storage";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    select: { id: true, sectionId: true, pdfKey: true },
  });
  if (!article?.pdfKey) return Response.json({ error: "Not found" }, { status: 404 });

  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!(await canReadArticle(user, article))) return forbidden("Subscription required");

  return Response.json({ url: await signedPdfUrl(article.pdfKey) });
}
