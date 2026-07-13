#!/usr/bin/env bash
# ==========================================================================
# IJRI — remove a user account COMPLETELY (default: admin@ijri.in).
# A user can't just be deleted (articles/reviews reference it), so this:
#   1. ensures the info@ijrein.org super admin exists,
#   2. reassigns the user's submitted articles to the super admin,
#   3. moves their chief-editor decisions to the super admin,
#   4. deletes their reviews, review assignments, subscriptions, purchases,
#   5. deletes the account.
# Usage (repo root, DATABASE_URL in env or .env):
#   bash remove-user.sh                     # removes admin@ijri.in
#   bash remove-user.sh someone@else.com    # removes another account
# ==========================================================================
set -euo pipefail
[ -f package.json ] || { echo "Run from repo root."; exit 1; }
if [ -z "${DATABASE_URL:-}" ] && [ -f .env ]; then
  export DATABASE_URL="$(grep -E '^DATABASE_URL=' .env | tail -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
[ -n "${DATABASE_URL:-}" ] || { echo "Set DATABASE_URL (env or .env)."; exit 1; }
TARGET="${1:-admin@ijri.in}"

TARGET="$TARGET" node - << 'NODE'
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new PrismaClient();
const email = process.env.TARGET;
const SUPER = "info@ijrein.org";

(async () => {
  if (email === SUPER) { console.error("Refusing to remove the protected super admin."); process.exit(1); }

  const user = await prisma.user.findUnique({ where: { email }, select: { id: true, name: true } });
  if (!user) { console.log(`No account found for ${email} — nothing to do.`); return; }

  const hash = await bcrypt.hash("Admin@123", 10);
  const admin = await prisma.user.upsert({
    where: { email: SUPER },
    update: { role: "ADMIN", approved: true },
    create: { email: SUPER, name: "IJRI Super Admin", role: "ADMIN", approved: true, passwordHash: hash },
  });

  const [arts, decs] = await Promise.all([
    prisma.article.updateMany({ where: { submittedById: user.id }, data: { submittedById: admin.id } }),
    prisma.article.updateMany({ where: { chiefEditorId: user.id }, data: { chiefEditorId: admin.id } }),
  ]);
  const reviews = await prisma.review.deleteMany({ where: { editorId: user.id } });
  let assigns = { count: 0 };
  try { assigns = await prisma.reviewAssignment.deleteMany({ where: { editorId: user.id } }); } catch { /* model may not exist yet */ }
  const subs = await prisma.subscription.deleteMany({ where: { userId: user.id } });
  const purch = await prisma.articlePurchase.deleteMany({ where: { userId: user.id } });
  await prisma.user.delete({ where: { id: user.id } });

  console.log(`Removed ${email} ("${user.name}").`);
  console.log(`  submissions reassigned to ${SUPER}: ${arts.count}`);
  console.log(`  decisions reassigned: ${decs.count}`);
  console.log(`  reviews deleted: ${reviews.count} · assignments: ${assigns.count} · subscriptions: ${subs.count} · purchases: ${purch.count}`);
})().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
NODE
