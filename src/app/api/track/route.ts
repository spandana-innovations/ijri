import { prisma } from "@/lib/prisma";
import { deviceClass } from "@/lib/device";
import type { EventType } from "@prisma/client";

const ALLOWED: EventType[] = ["VIEW", "DOWNLOAD", "SHARE"];

export async function POST(req: Request) {
  const b = await req.json().catch(() => null);
  const articleId = String(b?.articleId ?? "");
  const type = String(b?.type ?? "") as EventType;
  if (!articleId || !ALLOWED.includes(type)) return Response.json({ ok: false }, { status: 400 });

  const device = deviceClass(req.headers.get("x-ua") || req.headers.get("user-agent"));
  try {
    // Only record events for real, published articles.
    const exists = await prisma.article.findFirst({ where: { id: articleId, status: "PUBLISHED" }, select: { id: true } });
    if (exists) await prisma.articleEvent.create({ data: { articleId, type, device } });
  } catch {
    /* best-effort */
  }
  return Response.json({ ok: true });
}
