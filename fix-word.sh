#!/usr/bin/env bash
# ==========================================================================
# IJRI — fix: getAccount() returns { id, name, email, role, approved } with no
# `affiliation`. Correct the Word route and page to stop reading acc.affiliation.
# Run in repo:  bash fix-word.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Fixing Word route/page affiliation typing..."

# ---------------------------------------------------------------- route
cat > src/app/api/submissions/word/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!acc.approved && !isStaff(acc.role)) return forbidden("Your author account is awaiting approval");

  const b = await req.json().catch(() => null);
  const title = String(b?.title ?? "").trim();
  const abstract = String(b?.abstract ?? "").trim();
  const authorNames = String(b?.authorNames ?? "").trim() || acc.name;
  const affiliation = b?.affiliation ? String(b.affiliation).trim() : null;
  const sectionId = String(b?.sectionId ?? "");
  const bodyHtml = sanitize(String(b?.bodyHtml ?? ""));

  if (!title || !abstract || !sectionId || !bodyHtml.trim()) return Response.json({ error: "Missing required fields" }, { status: 400 });

  const section = await prisma.section.findUnique({ where: { id: sectionId }, select: { id: true } });
  if (!section) return Response.json({ error: "Invalid section" }, { status: 400 });

  const article = await prisma.article.create({
    data: { title, abstract, authorNames, affiliation, sectionId, bodyHtml, status: "SUBMITTED", submittedById: acc.id },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}
IJRI_EOF

# ---------------------------------------------------------------- page (prefill affiliation via prisma)
cat > src/app/submit/word/page.tsx << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import WordSubmit from "./WordSubmit";

export const dynamic = "force-dynamic";

export default async function WordSubmitPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!acc.approved && !isStaff(acc.role)) redirect("/pending");

  const [sections, me] = await Promise.all([
    prisma.section.findMany({ orderBy: { name: "asc" }, select: { id: true, name: true } }),
    prisma.user.findUnique({ where: { id: acc.id }, select: { affiliation: true } }),
  ]);

  return <WordSubmit sections={sections} defaultAuthor={acc.name} defaultAffiliation={me?.affiliation ?? ""} />;
}
IJRI_EOF

echo ""
echo "Fixed. Now run:  npm run build   (then commit & push)"
