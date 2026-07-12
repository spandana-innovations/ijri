import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

const slugify = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

export async function GET(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden();
  const sections = await prisma.section.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { articles: true } } },
  });
  return Response.json(sections);
}

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN") return forbidden("Only an administrator can add sections");
  const body = await req.json().catch(() => null);
  const name = String(body?.name ?? "").trim();
  if (!name) return Response.json({ error: "Section name required" }, { status: 400 });
  const slug = slugify(name);
  const existing = await prisma.section.findFirst({ where: { OR: [{ name }, { slug }] } });
  if (existing) return Response.json({ error: "Section already exists" }, { status: 409 });
  const section = await prisma.section.create({ data: { name, slug } });
  return Response.json(section, { status: 201 });
}

export async function DELETE(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (acc.role !== "ADMIN") return forbidden("Only an administrator can remove sections");
  const body = await req.json().catch(() => null);
  const id = String(body?.id ?? "");
  if (!id) return Response.json({ error: "Missing id" }, { status: 400 });
  const count = await prisma.article.count({ where: { sectionId: id } });
  if (count > 0) return Response.json({ error: `Cannot delete: ${count} article(s) use this section` }, { status: 409 });
  await prisma.section.delete({ where: { id } });
  return Response.json({ ok: true });
}
