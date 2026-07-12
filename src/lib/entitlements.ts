import { prisma } from "./prisma";
import { isStaff } from "./auth";
import type { Role } from "@prisma/client";

export async function canReadArticle(
  user: { id: string; role: Role } | null,
  article: { id: string; sectionId: string }
): Promise<boolean> {
  if (!user) return false;
  if (isStaff(user.role)) return true;
  const now = new Date();

  const sub = await prisma.subscription.findFirst({
    where: {
      userId: user.id, status: "ACTIVE",
      startsAt: { lte: now }, endsAt: { gte: now },
      OR: [
        { plan: { in: ["MONTHLY", "ANNUAL", "PRINT_DIGITAL"] } },
        { plan: "SECTION", sectionId: article.sectionId },
      ],
    },
    select: { id: true },
  });
  if (sub) return true;

  const purchase = await prisma.articlePurchase.findUnique({
    where: { userId_articleId: { userId: user.id, articleId: article.id } },
    select: { id: true },
  });
  return Boolean(purchase);
}
