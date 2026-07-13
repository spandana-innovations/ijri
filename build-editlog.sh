#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#8) article edit log. Snapshots the manuscript on every resubmit,
# and shows a version history (before/after) to the author and to editors.
# Includes the #12 profile fields in the schema (superset), so run this AFTER
# build-profile.sh (or on its own) then a single db push.
# Run in repo:  bash build-editlog.sh  ->  npx prisma db push  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Edit log..."

BASE="src/app"
[ -d "src/app/(backend)" ] && BASE="src/app/(backend)"
mkdir -p "$BASE/history/[id]" "src/app/api/submissions/[id]/resubmit"
echo "  history page -> $BASE/history/[id]"

# ---------------------------------------------------------------- schema (superset: profile + revisions)
cat > prisma/schema.prisma << 'IJRI_EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  AUTHOR
  EDITOR
  CHIEF_EDITOR
  ADMIN
}

enum ArticleStatus {
  SUBMITTED
  UNDER_REVIEW
  REVIEWED
  REVISION_REQUESTED
  PUBLISHED
  REJECTED
}

enum Recommendation {
  ACCEPT
  MINOR_REVISION
  MAJOR_REVISION
  REJECT
}

enum PlanType {
  MONTHLY
  ANNUAL
  PRINT_DIGITAL
  SECTION
}

enum SubscriptionStatus {
  ACTIVE
  EXPIRED
  CANCELLED
}

enum EventType {
  VIEW
  DOWNLOAD
  SHARE
}

model User {
  id            String   @id @default(cuid())
  email         String   @unique
  name          String
  role          Role     @default(AUTHOR)
  approved      Boolean  @default(false)
  affiliation   String?
  designation   String?
  orcid         String?
  website       String?
  bio           String?  @db.Text
  image         String?
  passwordHash  String?
  createdAt     DateTime @default(now())
  submitted     Article[]         @relation("SubmittedBy")
  reviews       Review[]
  decisions     Article[]         @relation("DecidedBy")
  subscriptions Subscription[]
  purchases     ArticlePurchase[]
}

model Section {
  id       String         @id @default(cuid())
  name     String         @unique
  slug     String         @unique
  articles Article[]
  subs     Subscription[]
}

model Issue {
  id          String    @id @default(cuid())
  volume      Int
  number      Int
  label       String
  isCurrent   Boolean   @default(false)
  publishedAt DateTime?
  articles    Article[]

  @@unique([volume, number])
}

model Article {
  id             String        @id @default(cuid())
  title          String
  abstract       String
  bodyHtml       String?       @db.Text
  coverImage     String?
  authorNames    String
  affiliation    String?
  status         ArticleStatus @default(SUBMITTED)
  editorFeedback String?       @db.Text
  revisionCount  Int           @default(0)
  section        Section       @relation(fields: [sectionId], references: [id])
  sectionId      String
  issue          Issue?        @relation(fields: [issueId], references: [id])
  issueId        String?
  startPage      Int?
  endPage        Int?
  doi            String?       @unique
  pdfKey         String?
  submittedBy    User          @relation("SubmittedBy", fields: [submittedById], references: [id])
  submittedById  String
  chiefEditor    User?         @relation("DecidedBy", fields: [chiefEditorId], references: [id])
  chiefEditorId  String?
  decidedAt      DateTime?
  reviews        Review[]
  purchases      ArticlePurchase[]
  events         ArticleEvent[]
  revisions      ArticleRevision[]
  createdAt      DateTime      @default(now())
  publishedAt    DateTime?

  @@index([status])
  @@index([issueId])
}

model Review {
  id             String         @id @default(cuid())
  article        Article        @relation(fields: [articleId], references: [id])
  articleId      String
  editor         User           @relation(fields: [editorId], references: [id])
  editorId       String
  recommendation Recommendation
  comments       String?        @db.Text
  createdAt      DateTime       @default(now())

  @@unique([articleId, editorId])
}

model Subscription {
  id        String             @id @default(cuid())
  user      User               @relation(fields: [userId], references: [id])
  userId    String
  plan      PlanType
  status    SubscriptionStatus @default(ACTIVE)
  print     Boolean            @default(false)
  section   Section?           @relation(fields: [sectionId], references: [id])
  sectionId String?
  startsAt  DateTime           @default(now())
  endsAt    DateTime
  createdAt DateTime           @default(now())

  @@index([userId, status])
}

model ArticlePurchase {
  id        String   @id @default(cuid())
  user      User     @relation(fields: [userId], references: [id])
  userId    String
  article   Article  @relation(fields: [articleId], references: [id])
  articleId String
  createdAt DateTime @default(now())

  @@unique([userId, articleId])
}

model ArticleEvent {
  id        String    @id @default(cuid())
  article   Article   @relation(fields: [articleId], references: [id])
  articleId String
  type      EventType
  device    String?
  createdAt DateTime  @default(now())

  @@index([articleId, type])
  @@index([type, createdAt])
}

model ArticleRevision {
  id           String   @id @default(cuid())
  article      Article  @relation(fields: [articleId], references: [id])
  articleId    String
  title        String
  abstract     String
  bodyHtml     String?  @db.Text
  editedByName String
  createdAt    DateTime @default(now())

  @@index([articleId, createdAt])
}
IJRI_EOF

# ---------------------------------------------------------------- resubmit route: snapshot before update
cat > "src/app/api/submissions/[id]/resubmit/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const article = await prisma.article.findUnique({ where: { id }, select: { submittedById: true, status: true, title: true, abstract: true, bodyHtml: true } });
  if (!article) return Response.json({ error: "Not found" }, { status: 404 });
  if (article.submittedById !== acc.id) return forbidden("You can only revise your own submissions");
  if (article.status !== "REVISION_REQUESTED") return Response.json({ error: "This submission is not open for revision" }, { status: 409 });

  const b = await req.json().catch(() => null);
  const { title, abstract, bodyHtml } = b ?? {};
  if (!title || !abstract || !bodyHtml) return Response.json({ error: "Missing required fields" }, { status: 400 });

  // snapshot the version that is about to be replaced (the "before")
  await prisma.articleRevision.create({
    data: { articleId: id, title: article.title, abstract: article.abstract, bodyHtml: article.bodyHtml, editedByName: acc.name },
  });

  const updated = await prisma.article.update({
    where: { id },
    data: { title, abstract, bodyHtml, status: "SUBMITTED", revisionCount: { increment: 1 } },
    select: { id: true, status: true },
  });
  return Response.json(updated);
}
IJRI_EOF

# ---------------------------------------------------------------- history page
cat > "$BASE/history/[id]/page.tsx" << 'IJRI_EOF'
import Link from "next/link";
import { redirect, notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";
import { T, Eyebrow, Chip } from "@/lib/ui";
import { IconArchive } from "@/lib/icons";

export const dynamic = "force-dynamic";

function Version({ tag, when, who, title, abstract, bodyHtml, open }: { tag: string; when: string; who?: string; title: string; abstract: string; bodyHtml: string; open?: boolean }) {
  return (
    <details open={open} style={{ border: `1px solid ${T.rule}`, marginBottom: 12 }}>
      <summary style={{ cursor: "pointer", padding: "12px 16px", background: T.g50, fontFamily: T.sans, fontSize: 13, display: "flex", gap: 10, alignItems: "center" }}>
        <Chip>{tag}</Chip><strong style={{ fontFamily: T.serif, fontSize: 16 }}>{title}</strong>
        <span style={{ marginLeft: "auto", color: T.muted, fontSize: 12 }}>{when}{who ? ` · ${who}` : ""}</span>
      </summary>
      <div style={{ padding: "14px 18px" }}>
        <Eyebrow>Abstract</Eyebrow>
        <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.55, color: "#333", margin: "6px 0 14px" }}>{abstract}</p>
        <Eyebrow>Body</Eyebrow>
        <div className="body" style={{ marginTop: 6 }} dangerouslySetInnerHTML={{ __html: bodyHtml }} />
      </div>
    </details>
  );
}

export default async function History({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount();
  if (!acc) redirect("/login");

  const art = await prisma.article.findUnique({ where: { id }, select: { id: true, title: true, abstract: true, bodyHtml: true, submittedById: true, revisionCount: true, createdAt: true } });
  if (!art) notFound();
  if (art.submittedById !== acc.id && !isStaff(acc.role)) redirect("/dashboard");

  const revisions = await prisma.articleRevision.findMany({ where: { articleId: id }, orderBy: { createdAt: "desc" } });

  return (
    <main style={{ maxWidth: 800, margin: "0 auto", padding: "36px 20px 56px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconArchive size={22} /><Eyebrow inverse>Edit history</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,32px)", margin: "10px 0 6px" }}>{art.title}</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 20px" }}>
        {revisions.length === 0 ? "No edits recorded yet — this is the original submission." : `${revisions.length} earlier version${revisions.length === 1 ? "" : "s"} recorded. Newest first.`}
      </p>

      <Version tag="Current" when="latest" title={art.title} abstract={art.abstract} bodyHtml={sanitize(art.bodyHtml ?? "")} open />
      {revisions.map((r) => (
        <Version key={r.id} tag="Before edit" when={new Date(r.createdAt).toLocaleString()} who={r.editedByName} title={r.title} abstract={r.abstract} bodyHtml={sanitize(r.bodyHtml ?? "")} />
      ))}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- link from My submissions
MS=""
for c in "src/app/(backend)/my-submissions/page.tsx" "src/app/my-submissions/page.tsx"; do [ -f "$c" ] && MS="$c" && break; done
if [ -n "$MS" ]; then
  MS="$MS" node - << 'NODE'
const fs=require("fs"); const p=process.env.MS; let s=fs.readFileSync(p,"utf8");
const anchor=`<h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 20, margin: "8px 0 4px" }}>{a.title}</h3>`;
const add=anchor+`\n          <Link href={\`/history/\${a.id}\`} style={{ fontFamily: T.sans, fontSize: 12, textDecoration: "underline", color: T.muted }}>Edit history \u2192</Link>`;
if(s.includes(`/history/`)) console.log("  my-submissions already links history");
else if(s.includes(anchor)){ fs.writeFileSync(p,s.replace(anchor,add)); console.log("  my-submissions: edit-history link added"); }
else console.log("  WARN: my-submissions title line not found");
NODE
fi

# ---------------------------------------------------------------- link from Review desk detail
ED=""
for c in "src/app/(backend)/editor/[id]/page.tsx" "src/app/editor/[id]/page.tsx"; do [ -f "$c" ] && ED="$c" && break; done
if [ -n "$ED" ]; then
  ED="$ED" node - << 'NODE'
const fs=require("fs"); const p=process.env.ED; let s=fs.readFileSync(p,"utf8");
const anchor=`return <ReviewDesk me={{ id: acc.id, role: acc.role }} article={article} issues={issues} myRecommendation={myReview?.recommendation ?? null} myComments={myReview?.comments ?? ""} />;`;
const repl=`return (\n    <>\n      <div style={{ maxWidth: 760, margin: "0 auto", padding: "18px 20px 0" }}>\n        <a href={\`/history/\${a.id}\`} style={{ fontFamily: "ui-sans-serif, system-ui, sans-serif", fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", textDecoration: "underline" }}>Edit history \u2192</a>\n      </div>\n      <ReviewDesk me={{ id: acc.id, role: acc.role }} article={article} issues={issues} myRecommendation={myReview?.recommendation ?? null} myComments={myReview?.comments ?? ""} />\n    </>\n  );`;
if(s.includes(`/history/`)) console.log("  review desk already links history");
else if(s.includes(anchor)){ fs.writeFileSync(p,s.replace(anchor,repl)); console.log("  review desk: edit-history link added"); }
else console.log("  WARN: review desk return not found");
NODE
fi

echo ""
echo "Edit log written. Now run:  npx prisma db push  &&  npm run build"
