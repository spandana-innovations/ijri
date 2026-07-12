import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";

// POST /api/auth/register  { email, password, name, affiliation? }
// New accounts are AUTHORs. Editor/chief roles are granted by an admin.
export async function POST(req: Request) {
  const { email, password, name, affiliation } = (await req.json()) ?? {};
  if (!email || !password || !name) {
    return Response.json({ error: "email, password and name are required" }, { status: 400 });
  }
  const lower = String(email).toLowerCase();
  const exists = await prisma.user.findUnique({ where: { email: lower } });
  if (exists) return Response.json({ error: "Email already registered" }, { status: 409 });

  const passwordHash = await bcrypt.hash(String(password), 10);
  const user = await prisma.user.create({
    data: { email: lower, name, affiliation, passwordHash, role: "AUTHOR" },
    select: { id: true, email: true, name: true, role: true },
  });
  return Response.json(user, { status: 201 });
}
