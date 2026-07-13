#!/usr/bin/env bash
# ==========================================================================
# IJRI — ensure info@ijrein.org exists as the super admin (ADMIN, approved).
# Password set to Admin@123. Run from repo root (needs node_modules + DB).
#   bash make-superadmin.sh
# ==========================================================================
set -euo pipefail
[ -f package.json ] || { echo "Run from repo root."; exit 1; }
if [ -z "${DATABASE_URL:-}" ] && [ -f .env ]; then
  export DATABASE_URL="$(grep -E '^DATABASE_URL=' .env | tail -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
[ -n "${DATABASE_URL:-}" ] || { echo "Set DATABASE_URL (env or .env)."; exit 1; }

node - << 'NODE'
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new PrismaClient();
(async () => {
  const email = "info@ijrein.org";
  const hash = await bcrypt.hash("Admin@123", 10);
  const u = await prisma.user.upsert({
    where: { email },
    update: { role: "ADMIN", approved: true, passwordHash: hash },
    create: { email, name: "IJRI Super Admin", role: "ADMIN", approved: true, passwordHash: hash },
  });
  console.log(`Super admin ready: ${email} (id ${u.id}) — password Admin@123`);
})().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
NODE
