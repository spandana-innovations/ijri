import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

export async function POST(req: Request) {
  const body = await req.json().catch(() => null);
  const email = String(body?.email ?? "").toLowerCase().trim();
  const password = String(body?.password ?? "");
  const name = String(body?.name ?? "").trim();
  const affiliation = body?.affiliation ? String(body.affiliation) : null;
  if (!email || !password || !name) return Response.json({ error: "Missing required fields" }, { status: 400 });
  if (password.length < 8) return Response.json({ error: "Password must be at least 8 characters" }, { status: 400 });

  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return Response.json({ error: "Email already registered" }, { status: 409 });

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: { email, name, affiliation, passwordHash, role: "AUTHOR" },
    select: { id: true, email: true, name: true, role: true },
  });
  return Response.json(user, { status: 201 });
}
