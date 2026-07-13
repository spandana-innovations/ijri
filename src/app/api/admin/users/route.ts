import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

const SUPER = "info@ijrein.org";
const ROLES = ["AUTHOR", "EDITOR", "CHIEF_EDITOR", "ADMIN"];

async function requireManager(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return { err: unauthorized() };
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return { err: forbidden("Managers only") };
  return { acc };
}

export async function GET(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const users = await prisma.user.findMany({
    orderBy: [{ approved: "asc" }, { createdAt: "asc" }],
    select: { id: true, name: true, email: true, role: true, approved: true, affiliation: true, designation: true, image: true, createdAt: true },
  });
  return Response.json({ users });
}

export async function PATCH(req: Request) {
  const { acc, err } = await requireManager(req);
  if (err) return err;

  const b = await req.json().catch(() => null);
  const userId = String(b?.userId ?? "");
  const action = String(b?.action ?? "");
  const target = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, email: true, role: true } });
  if (!target) return Response.json({ error: "User not found" }, { status: 404 });

  const isSuper = target.email === SUPER;

  if (action === "approve") { await prisma.user.update({ where: { id: userId }, data: { approved: true } }); return Response.json({ ok: true }); }
  if (action === "unapprove") {
    if (isSuper) return Response.json({ error: "The super admin account is protected" }, { status: 403 });
    await prisma.user.update({ where: { id: userId }, data: { approved: false } });
    return Response.json({ ok: true });
  }
  if (action === "role") {
    const role = String(b?.role ?? "");
    if (!ROLES.includes(role)) return Response.json({ error: "Invalid role" }, { status: 400 });
    if (isSuper && role !== "ADMIN") return Response.json({ error: "The super admin account must remain an administrator" }, { status: 403 });
    if (role === "CHIEF_EDITOR") {
      // only one chief editor
      await prisma.user.updateMany({ where: { role: "CHIEF_EDITOR", id: { not: userId } }, data: { role: "EDITOR" } });
    }
    await prisma.user.update({ where: { id: userId }, data: { role: role as never, approved: true } });
    return Response.json({ ok: true });
  }
  return Response.json({ error: "Unknown action" }, { status: 400 });
}
