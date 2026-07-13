import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!acc.approved && !isStaff(acc.role)) return forbidden("Your author account is awaiting approval");

  const b = await req.json().catch(() => null);
  const title = String(b?.title ?? "").trim();
  const abstract = String(b?.abstract ?? "").trim();
  const authorNames = String(b?.authorNames ?? "").trim() || acc.name;
  const affiliation = b?.affiliation ? String(b.affiliation).trim() : (acc.affiliation ?? null);
  const sectionId = String(b?.sectionId ?? "");
  const bodyHtml = sanitize(String(b?.bodyHtml ?? ""));

  if (!title || !abstract || !sectionId || !bodyHtml.trim()) return Response.json({ error: "Missing required fields" }, { status: 400 });

  const section = await prisma.section.findUnique({ where: { id: sectionId }, select: { id: true } });
  if (!section) return Response.json({ error: "Invalid section" }, { status: 400 });

  const article = await prisma.article.create({
    data: { title, abstract, authorNames, affiliation, sectionId, bodyHtml, status: "SUBMITTED", submittedById: acc.id },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}
