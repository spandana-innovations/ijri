import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");

  const b = await req.json().catch(() => null);
  const action = String(b?.action ?? "");

  if (action === "add") {
    const editorId = String(b?.editorId ?? "");
    if (!editorId) return Response.json({ error: "Choose an editor" }, { status: 400 });
    await prisma.reviewAssignment.upsert({ where: { articleId_editorId: { articleId: id, editorId } }, update: {}, create: { articleId: id, editorId } });
    return Response.json({ ok: true });
  }
  if (action === "send") {
    const count = await prisma.reviewAssignment.count({ where: { articleId: id } });
    if (count < 2) return Response.json({ error: "Assign at least two editors first" }, { status: 400 });
    await prisma.article.update({ where: { id }, data: { status: "UNDER_REVIEW" } });
    return Response.json({ ok: true });
  }
  return Response.json({ error: "Unknown action" }, { status: 400 });
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");
  const b = await req.json().catch(() => null);
  const editorId = String(b?.editorId ?? "");
  await prisma.reviewAssignment.deleteMany({ where: { articleId: id, editorId } });
  return Response.json({ ok: true });
}
