import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

async function requireManager(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return { err: unauthorized() };
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") return { err: forbidden("Managers only") };
  return { acc };
}

export async function GET(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, include: { _count: { select: { articles: true } } } });
  return Response.json({ sections: sections.map((s) => ({ id: s.id, name: s.name, slug: s.slug, articles: s._count.articles })) });
}

export async function POST(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const b = await req.json().catch(() => null);
  const name = String(b?.name ?? "").trim();
  if (!name) return Response.json({ error: "Name is required" }, { status: 400 });
  const s = slug(name);
  const existing = await prisma.section.findFirst({ where: { OR: [{ name }, { slug: s }] }, select: { id: true } });
  if (existing) return Response.json({ error: "That section already exists" }, { status: 409 });
  await prisma.section.create({ data: { name, slug: s } });
  return Response.json({ ok: true }, { status: 201 });
}

export async function DELETE(req: Request) {
  const { err } = await requireManager(req);
  if (err) return err;
  const b = await req.json().catch(() => null);
  const id = String(b?.id ?? "");
  const count = await prisma.article.count({ where: { sectionId: id } });
  if (count > 0) return Response.json({ error: `Cannot delete — ${count} article(s) use this section` }, { status: 409 });
  await prisma.section.delete({ where: { id } });
  return Response.json({ ok: true });
}
