import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";
import { computeSimilarity } from "@/lib/similarity";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");
  const result = await computeSimilarity(id);
  if (result) {
    await prisma.article.update({ where: { id }, data: { similarityScore: result.score, similarityMatchesJson: JSON.stringify(result.matches) } }).catch(() => {});
  }
  return Response.json(result ?? { score: 0, matches: [] });
}
