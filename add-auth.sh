#!/usr/bin/env bash
# ==========================================================================
# IJRI — add real authentication (Auth.js v5 / NextAuth) with roles.
# Run inside the repo:  bash add-auth.sh
# Then:  npm install next-auth@beta bcryptjs && npm install -D @types/bcryptjs
# ==========================================================================
set -euo pipefail
echo "Adding auth..."

mkdir -p types \
         "src/app/api/auth/[...nextauth]" \
         src/app/api/auth/register

# ---------------------------------------------------------------- src/auth.ts
cat > src/auth.ts << 'IJRI_EOF'
import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import bcrypt from "bcryptjs";
import { prisma } from "@/lib/prisma";

export const { handlers, auth, signIn, signOut } = NextAuth({
  session: { strategy: "jwt" },
  trustHost: true, // required behind Railway's proxy
  providers: [
    Credentials({
      credentials: { email: {}, password: {} },
      async authorize(creds) {
        const email = String(creds?.email ?? "").toLowerCase();
        const password = String(creds?.password ?? "");
        if (!email || !password) return null;
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user?.passwordHash) return null;
        const ok = await bcrypt.compare(password, user.passwordHash);
        if (!ok) return null;
        return { id: user.id, name: user.name, email: user.email, role: user.role };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = (user as { id: string }).id;
        token.role = (user as { role: string }).role;
      }
      return token;
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as { id?: string }).id = token.id as string;
        (session.user as { role?: string }).role = token.role as string;
      }
      return session;
    },
  },
});
IJRI_EOF

# ------------------------------------------- api/auth/[...nextauth]/route.ts
cat > "src/app/api/auth/[...nextauth]/route.ts" << 'IJRI_EOF'
import { handlers } from "@/auth";
export const { GET, POST } = handlers;
IJRI_EOF

# ------------------------------------------------- api/auth/register/route.ts
cat > src/app/api/auth/register/route.ts << 'IJRI_EOF'
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
IJRI_EOF

# ---------------------------------------------------------- src/lib/auth.ts
cat > src/lib/auth.ts << 'IJRI_EOF'
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
IJRI_EOF

# -------------------------------------------------- types/next-auth.d.ts
cat > types/next-auth.d.ts << 'IJRI_EOF'
import { DefaultSession } from "next-auth";
import type { Role } from "@prisma/client";

declare module "next-auth" {
  interface Session {
    user: { id: string; role: Role } & DefaultSession["user"];
  }
}
declare module "next-auth/jwt" {
  interface JWT {
    id?: string;
    role?: Role;
  }
}
IJRI_EOF

# ---------------------------------------------------------- prisma/seed.ts
cat > prisma/seed.ts << 'IJRI_EOF'
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
const prisma = new PrismaClient();

const SECTIONS = [
  "Computer Science", "Medicine & Public Health", "Engineering",
  "Economics", "Materials Science", "Social Science",
];
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

// Temporary passwords for seeded staff — CHANGE THESE after first login.
const DEFAULT_PASSWORD = "ChangeMe#2026";

async function main() {
  for (const name of SECTIONS) {
    await prisma.section.upsert({
      where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name) },
    });
  }

  await prisma.issue.upsert({
    where: { volume_number: { volume: 1, number: 1 } },
    update: { isCurrent: true },
    create: { volume: 1, number: 1, label: "July 2026", isCurrent: true, publishedAt: new Date() },
  });

  const hash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
  const staff = [
    { email: "admin@ijri.in", name: "IJRI Admin", role: "ADMIN" as const },
    { email: "snagaraj@iisc.ac.in", name: "Prof. S. Nagaraj", role: "CHIEF_EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "arao@iisc.ac.in", name: "Dr. Ananya Rao", role: "EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "riyer@iitm.ac.in", name: "Dr. Rohan Iyer", role: "EDITOR" as const, affiliation: "IIT Madras" },
  ];
  for (const u of staff) {
    await prisma.user.upsert({
      where: { email: u.email },
      update: { role: u.role, passwordHash: hash },
      create: { ...u, passwordHash: hash },
    });
  }
  console.log(`Seed complete. Staff password: ${DEFAULT_PASSWORD} (change after first login).`);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
IJRI_EOF

echo ""
echo "Auth files written."
echo "Now run:"
echo "  npm install next-auth@beta bcryptjs && npm install -D @types/bcryptjs"
echo "  npm run seed        # sets staff passwords"
echo "  npm run build       # verify it compiles"
