import { prisma } from "./prisma";
import type { Role } from "@prisma/client";

// STUB: replace the token lookup with a real session layer (NextAuth / Better
// Auth). Routes depend only on getCurrentUser() returning { id, role } or null.
export async function getCurrentUser(req: Request) {
  const auth = req.headers.get("authorization");
  const userId = auth?.startsWith("Bearer ") ? auth.slice(7) : null; // TODO: verify a real JWT/session
  if (!userId) return null;
  return prisma.user.findUnique({
    select: { id: true, role: true, name: true, email: true },
    where: { id: userId },
  });
}
export function isStaff(role?: Role) {
  return role === "EDITOR" || role === "CHIEF_EDITOR" || role === "ADMIN";
}
export function unauthorized(message = "Sign in required") {
  return Response.json({ error: message }, { status: 401 });
}
export function forbidden(message = "Not permitted") {
  return Response.json({ error: message }, { status: 403 });
}
