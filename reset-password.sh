#!/usr/bin/env bash
# ==========================================================================
# IJRI — set account passwords directly (admin/ops tool).
#   One account:  bash reset-password.sh someone@ijrein.org 'NewStrongPass#1'
#   All accounts: bash reset-password.sh --all 'SharedPass#2026'
#
# Reads DATABASE_URL from env or .env. Uses the app's own bcrypt + Prisma.
# Run from the repo root (needs node_modules).
# ==========================================================================
set -euo pipefail
[ -f package.json ] || { echo "Run from the repo root."; exit 1; }

if [ -z "${DATABASE_URL:-}" ] && [ -f .env ]; then
  export DATABASE_URL="$(grep -E '^DATABASE_URL=' .env | tail -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
[ -n "${DATABASE_URL:-}" ] || { echo "Set DATABASE_URL (env or .env)."; exit 1; }

MODE="${1:-}"; PW="${2:-}"
[ -n "$MODE" ] && [ -n "$PW" ] || { echo "Usage: reset-password.sh <email|--all> <newPassword>"; exit 1; }

MODE="$MODE" PW="$PW" node - << 'NODE'
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new PrismaClient();
const mode = process.env.MODE, pw = process.env.PW;

(async () => {
  if (pw.length < 8) { console.error("Password should be at least 8 characters."); process.exit(1); }
  const hash = await bcrypt.hash(pw, 10);
  if (mode === "--all") {
    const r = await prisma.user.updateMany({ data: { passwordHash: hash } });
    console.log(`Updated ${r.count} account(s) to the new password.`);
  } else {
    const u = await prisma.user.findUnique({ where: { email: mode }, select: { id: true } });
    if (!u) { console.error(`No account with email ${mode}`); process.exit(1); }
    await prisma.user.update({ where: { email: mode }, data: { passwordHash: hash } });
    console.log(`Password updated for ${mode}.`);
  }
})().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
NODE
