#!/usr/bin/env bash
# ==========================================================================
# IJRI — repair: recreate the core lib files the API routes import.
# Safe to run anytime; overwrites with correct content.
# Run in the repo:  bash repair-lib.sh  →  npm run build
# ==========================================================================
set -euo pipefail
mkdir -p src/lib
echo "Repairing src/lib ..."

cat > src/lib/prisma.ts << 'IJRI_EOF'
import { PrismaClient } from "@prisma/client";
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
export const prisma = globalForPrisma.prisma ?? new PrismaClient({ log: ["error", "warn"] });
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
IJRI_EOF

cat > src/lib/auth.ts << 'IJRI_EOF'
import { auth } from "@/auth";
import type { Role } from "@prisma/client";

// Session-backed current user. Optional arg keeps existing route signatures
// (getCurrentUser(req)) compiling; it is not used.
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

cat > src/lib/entitlements.ts << 'IJRI_EOF'
import { prisma } from "./prisma";
import { isStaff } from "./auth";
import type { Role } from "@prisma/client";

export async function canReadArticle(
  user: { id: string; role: Role } | null,
  article: { id: string; sectionId: string }
): Promise<boolean> {
  if (!user) return false;
  if (isStaff(user.role)) return true;
  const now = new Date();

  const sub = await prisma.subscription.findFirst({
    where: {
      userId: user.id, status: "ACTIVE",
      startsAt: { lte: now }, endsAt: { gte: now },
      OR: [
        { plan: { in: ["MONTHLY", "ANNUAL", "PRINT_DIGITAL"] } },
        { plan: "SECTION", sectionId: article.sectionId },
      ],
    },
    select: { id: true },
  });
  if (sub) return true;

  const purchase = await prisma.articlePurchase.findUnique({
    where: { userId_articleId: { userId: user.id, articleId: article.id } },
    select: { id: true },
  });
  return Boolean(purchase);
}
IJRI_EOF

cat > src/lib/storage.ts << 'IJRI_EOF'
import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({
  region: process.env.S3_REGION ?? "auto",
  endpoint: process.env.S3_ENDPOINT,
  forcePathStyle: true,
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY_ID ?? "",
    secretAccessKey: process.env.S3_SECRET_ACCESS_KEY ?? "",
  },
});
const BUCKET = process.env.S3_BUCKET ?? "";
const TTL = Number(process.env.PDF_URL_TTL ?? 300);

export async function signedPdfUrl(key: string): Promise<string> {
  return getSignedUrl(s3, new GetObjectCommand({ Bucket: BUCKET, Key: key }), { expiresIn: TTL });
}
IJRI_EOF

echo "Repaired. Now: npm run build"
echo "Then: git add . && git commit -m 'Repair lib files' && git push origin main"
