#!/usr/bin/env bash
# ==========================================================================
# IJRI — restore missing API routes that were lost during the workspace-root
# mixup. Recreates: health, auth/[...nextauth], auth/register,
# articles/[id]/pdf, submissions/[id]/reviews, submissions/[id]/decision.
# Run in the repo:  bash restore-api.sh
# ==========================================================================
set -euo pipefail
echo "Restoring API routes..."
mkdir -p src/app/api/health \
         "src/app/api/auth/[...nextauth]" \
         src/app/api/auth/register \
         "src/app/api/articles/[id]/pdf" \
         "src/app/api/submissions/[id]/reviews" \
         "src/app/api/submissions/[id]/decision"

# ---- health (Railway healthcheck hits this; keep it DB-free so deploys pass)
cat > src/app/api/health/route.ts << 'IJRI_EOF'
export const dynamic = "force-dynamic";
export async function GET() {
  return Response.json({ status: "ok", ts: Date.now() });
}
IJRI_EOF

# ---- NextAuth catch-all (serves signin/callback/session/csrf)
cat > "src/app/api/auth/[...nextauth]/route.ts" << 'IJRI_EOF'
import { handlers } from "@/auth";
export const { GET, POST } = handlers;
IJRI_EOF

# ---- register (public: creates an AUTHOR account)
cat > src/app/api/auth/register/route.ts << 'IJRI_EOF'
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
IJRI_EOF

# ---- article PDF (signed URL, entitlement-gated)
cat > "src/app/api/articles/[id]/pdf/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";
import { signedPdfUrl } from "@/lib/storage";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    select: { id: true, sectionId: true, pdfKey: true },
  });
  if (!article?.pdfKey) return Response.json({ error: "Not found" }, { status: 404 });

  const user = await getCurrentUser(req);
  const ok = await canReadArticle(user, article);
  if (!ok) return Response.json({ error: "Subscription required" }, { status: 402 });

  const url = await signedPdfUrl(article.pdfKey);
  return Response.json({ url });
}
IJRI_EOF

# ---- reviews (an editor records a recommendation)
cat > "src/app/api/submissions/[id]/reviews/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isStaff, unauthorized, forbidden } from "@/lib/auth";

const VALID = ["ACCEPT", "MINOR_REVISION", "MAJOR_REVISION", "REJECT"];

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!isStaff(user.role)) return forbidden();

  const body = await req.json().catch(() => null);
  const recommendation = String(body?.recommendation ?? "");
  const comments = body?.comments ? String(body.comments) : null;
  if (!VALID.includes(recommendation)) return Response.json({ error: "Invalid recommendation" }, { status: 400 });

  const review = await prisma.review.upsert({
    where: { articleId_editorId: { articleId: id, editorId: user.id } },
    update: { recommendation: recommendation as never, comments },
    create: { articleId: id, editorId: user.id, recommendation: recommendation as never, comments },
  });
  await prisma.article.update({ where: { id }, data: { status: "UNDER_REVIEW" } });
  return Response.json(review, { status: 201 });
}
IJRI_EOF

# ---- decision (Editor-in-Chief publishes or rejects)
cat > "src/app/api/submissions/[id]/decision/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (user.role !== "CHIEF_EDITOR" && user.role !== "ADMIN")
    return forbidden("Only the Editor-in-Chief can decide");

  const body = await req.json().catch(() => null);
  const decision = String(body?.decision ?? "");

  if (decision === "PUBLISH") {
    const article = await prisma.article.update({
      where: { id },
      data: {
        status: "PUBLISHED", chiefEditorId: user.id, decidedAt: new Date(), publishedAt: new Date(),
        issueId: body?.issueId ?? undefined,
        startPage: body?.startPage ?? undefined,
        endPage: body?.endPage ?? undefined,
      },
      select: { id: true, status: true },
    });
    return Response.json(article);
  }
  if (decision === "REJECT") {
    const article = await prisma.article.update({
      where: { id },
      data: { status: "REJECTED", chiefEditorId: user.id, decidedAt: new Date() },
      select: { id: true, status: true },
    });
    return Response.json(article);
  }
  return Response.json({ error: "Invalid decision" }, { status: 400 });
}
IJRI_EOF

echo ""
echo "API routes restored. Now run:"
echo "  npx prisma db push      # adds bodyHtml/coverImage columns (non-destructive)"
echo "  npm run seed            # seeds the 6 sample articles"
echo "  npm run build"
echo "  git add . && git commit -m 'Restore API routes + sync schema' && git push origin main"
