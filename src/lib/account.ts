import { prisma } from "./prisma";
import { getCurrentUser } from "./auth";

export async function getAccount(req?: Request) {
  const u = await getCurrentUser(req);
  if (!u) return null;
  return prisma.user.findUnique({
    where: { id: u.id },
    select: { id: true, name: true, email: true, role: true, approved: true },
  });
}
