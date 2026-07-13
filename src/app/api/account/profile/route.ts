import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized } from "@/lib/auth";

const MAX_IMAGE = 350_000; // ~350 KB data URL cap

export async function PATCH(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const b = await req.json().catch(() => null);
  const data: Record<string, string> = {};
  for (const f of ["name", "affiliation", "designation", "website", "linkedin", "twitter", "scholar"]) {
    if (typeof b?.[f] === "string") data[f] = b[f].trim();
  }
  if (typeof b?.bio === "string") data.bio = b.bio.replace(/<[^>]+>/g, "").trim(); // strictly plain text
  if (typeof b?.image === "string") {
    const img = b.image.trim();
    if (img === "" || img.startsWith("preset:")) data.image = img;
    else if (img.startsWith("data:image/") && img.length <= MAX_IMAGE) data.image = img;
    else return Response.json({ error: "Image is invalid or too large" }, { status: 400 });
  }
  if (typeof b?.email === "string" && b.email.trim()) {
    const email = b.email.trim().toLowerCase();
    const existing = await prisma.user.findUnique({ where: { email }, select: { id: true } });
    if (existing && existing.id !== acc.id) return Response.json({ error: "That email is already in use" }, { status: 409 });
    data.email = email;
  }
  if (data.name === "") return Response.json({ error: "Name is required" }, { status: 400 });

  await prisma.user.update({ where: { id: acc.id }, data });
  return Response.json({ ok: true });
}
