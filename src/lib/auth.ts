import { auth } from "@/auth";
import type { Role } from "@prisma/client";

// Real session-backed current user. The optional arg keeps the existing route
// signatures (getCurrentUser(req)) compiling; it is not used.
export async function getCurrentUser(_req?: Request) {
  const session = await auth();
  if (!session?.user) return null;
  const u = session.user as { id: string; role: Role; name?: string | null; email?: string | null };
  return { id: u.id, role: u.role, name: u.name ?? "", email: u.email ?? "" };
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
