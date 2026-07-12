import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const users = await prisma.user.findMany({
    orderBy: { createdAt: "desc" },
    select: { id: true, name: true, email: true, role: true, approved: true, affiliation: true, createdAt: true },
  });
  return Response.json(users);
}

export async function PATCH(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return forbidden("Only an administrator can change access");
  const body = await req.json().catch(() => null);
  const userId = String(body?.userId ?? "");
  if (!userId) return Response.json({ error: "Missing userId" }, { status: 400 });

  const data: { approved?: boolean; role?: "AUTHOR" | "EDITOR" } = {};
  if (typeof body?.approved === "boolean") data.approved = body.approved;
  if (body?.role === "AUTHOR" || body?.role === "EDITOR") data.role = body.role;

  const updated = await prisma.user.update({
    where: { id: userId }, data,
    select: { id: true, approved: true, role: true },
  });
  return Response.json(updated);
}
