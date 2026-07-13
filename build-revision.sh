#!/usr/bin/env bash
# ==========================================================================
# IJRI — revision loop (editor feedback -> author edits -> resubmit).
# Also adds the ArticleEvent model used by analytics (next script).
# Run in repo:  bash build-revision.sh  ->  npx prisma db push  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Revision loop + analytics schema..."
mkdir -p prisma "src/app/api/submissions/[id]/decision" "src/app/api/submissions/[id]/resubmit" \
         "src/app/editor/[id]" src/app/my-submissions

# ---------------------------------------------------------------- schema (revision fields + ArticleEvent)
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
  id           String        @id @default(cuid())
  title        String
  abstract     String
  bodyHtml     String?       @db.Text
  coverImage   String?
  authorNames  String
  affiliation  String?
  status       ArticleStatus @default(SUBMITTED)
  editorFeedback String?     @db.Text
  revisionCount Int          @default(0)
  section      Section       @relation(fields: [sectionId], references: [id])
  sectionId    String
  issue        Issue?        @relation(fields: [issueId], references: [id])
  issueId      String?
  startPage    Int?
  endPage      Int?
  doi          String?       @unique
  pdfKey       String?
  submittedBy   User     @relation("SubmittedBy", fields: [submittedById], references: [id])
  submittedById String
  chiefEditor   User?    @relation("DecidedBy", fields: [chiefEditorId], references: [id])
  chiefEditorId String?
  decidedAt     DateTime?
  reviews      Review[]
  purchases    ArticlePurchase[]
  events       ArticleEvent[]
  createdAt    DateTime  @default(now())
  publishedAt  DateTime?

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
IJRI_EOF

# ---------------------------------------------------------------- decision route (adds REVISE)
cat > "src/app/api/submissions/[id]/decision/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (user.role !== "CHIEF_EDITOR" && user.role !== "ADMIN") return forbidden("Only the Editor-in-Chief can decide");

  const body = await req.json().catch(() => null);
  const decision = String(body?.decision ?? "");

  if (decision === "PUBLISH") {
    const article = await prisma.article.update({
      where: { id },
      data: {
        status: "PUBLISHED", chiefEditorId: user.id, decidedAt: new Date(), publishedAt: new Date(),
        issueId: body?.issueId ?? undefined, startPage: body?.startPage ?? undefined, endPage: body?.endPage ?? undefined,
      }, select: { id: true, status: true },
    });
    return Response.json(article);
  }
  if (decision === "REJECT") {
    const article = await prisma.article.update({ where: { id }, data: { status: "REJECTED", chiefEditorId: user.id, decidedAt: new Date() }, select: { id: true, status: true } });
    return Response.json(article);
  }
  if (decision === "REVISE") {
    const feedback = String(body?.feedback ?? "").trim();
    if (!feedback) return Response.json({ error: "Feedback to the author is required" }, { status: 400 });
    const article = await prisma.article.update({ where: { id }, data: { status: "REVISION_REQUESTED", editorFeedback: feedback }, select: { id: true, status: true } });
    return Response.json(article);
  }
  return Response.json({ error: "Invalid decision" }, { status: 400 });
}
IJRI_EOF

# ---------------------------------------------------------------- resubmit route (author)
cat > "src/app/api/submissions/[id]/resubmit/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const article = await prisma.article.findUnique({ where: { id }, select: { submittedById: true, status: true } });
  if (!article) return Response.json({ error: "Not found" }, { status: 404 });
  if (article.submittedById !== acc.id) return forbidden("You can only revise your own submissions");
  if (article.status !== "REVISION_REQUESTED") return Response.json({ error: "This submission is not open for revision" }, { status: 409 });

  const b = await req.json().catch(() => null);
  const { title, abstract, bodyHtml } = b ?? {};
  if (!title || !abstract || !bodyHtml) return Response.json({ error: "Missing required fields" }, { status: 400 });

  const updated = await prisma.article.update({
    where: { id },
    data: { title, abstract, bodyHtml, status: "SUBMITTED", revisionCount: { increment: 1 } },
    select: { id: true, status: true },
  });
  return Response.json(updated);
}
IJRI_EOF

# ---------------------------------------------------------------- ReviewDesk (adds Request revision)
cat > "src/app/editor/[id]/ReviewDesk.tsx" << 'IJRI_EOF'
"use client";
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { T, Eyebrow, Chip } from "@/lib/ui";
import { IconScale } from "@/lib/icons";

type Review = { id: string; editorId: string; editorName: string; recommendation: string; comments: string | null };
type Issue = { id: string; volume: number; number: number; label: string; isCurrent: boolean };
type Article = {
  id: string; title: string; abstract: string; bodyHtml: string; authorNames: string; affiliation: string | null;
  status: string; section: string; submittedBy: { name: string; email: string; affiliation: string | null };
  issueId: string | null; startPage: number | null; endPage: number | null; reviews: Review[]; revisionCount: number;
};

const RECS: [string, string][] = [["ACCEPT", "Accept"], ["MINOR_REVISION", "Minor revision"], ["MAJOR_REVISION", "Major revision"], ["REJECT", "Reject"]];
const recLabel = (r: string) => RECS.find(([v]) => v === r)?.[1] ?? r;

export default function ReviewDesk({ me, article, issues, myRecommendation, myComments }:
  { me: { id: string; role: string }; article: Article; issues: Issue[]; myRecommendation: string | null; myComments: string }) {
  const router = useRouter();
  const canDecide = me.role === "CHIEF_EDITOR" || me.role === "ADMIN";
  const decided = article.status === "PUBLISHED" || article.status === "REJECTED";

  const [rec, setRec] = useState(myRecommendation ?? "ACCEPT");
  const [comments, setComments] = useState(myComments);
  const [issueId, setIssueId] = useState(article.issueId ?? issues.find((i) => i.isCurrent)?.id ?? issues[0]?.id ?? "");
  const [startPage, setStartPage] = useState(article.startPage?.toString() ?? "");
  const [endPage, setEndPage] = useState(article.endPage?.toString() ?? "");
  const [feedback, setFeedback] = useState("");
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);

  async function saveReview(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setMsg("");
    const r = await fetch(`/api/submissions/${article.id}/reviews`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ recommendation: rec, comments }) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save review"); return; }
    setMsg("Review saved."); router.refresh();
  }

  async function decide(decision: "PUBLISH" | "REJECT" | "REVISE") {
    if (decision === "REVISE" && !feedback.trim()) { setMsg("Enter feedback for the author before requesting a revision."); return; }
    setBusy(true); setMsg("");
    const body: Record<string, unknown> = { decision };
    if (decision === "PUBLISH") { body.issueId = issueId || undefined; body.startPage = startPage ? Number(startPage) : undefined; body.endPage = endPage ? Number(endPage) : undefined; }
    if (decision === "REVISE") body.feedback = feedback;
    const r = await fetch(`/api/submissions/${article.id}/decision`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not record decision"); return; }
    router.push("/editor"); router.refresh();
  }

  const box: React.CSSProperties = { border: `1px solid ${T.ink}`, padding: "18px 20px", margin: "22px 0" };
  const input: React.CSSProperties = { fontFamily: T.sans, fontSize: 14, padding: "9px 11px", border: `1px solid ${T.ink}`, background: T.paper };

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "32px 20px 48px" }}>
      <Link href="/editor" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Back to queue</Link>
      <div style={{ marginTop: 16, display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
        <Eyebrow inverse>{article.section}</Eyebrow>
        <Chip>{article.status.replace(/_/g, " ")}</Chip>
        {article.revisionCount > 0 && <Chip>Revision {article.revisionCount}</Chip>}
      </div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, lineHeight: 1.12, fontSize: "clamp(26px,5vw,38px)", margin: "14px 0 12px" }}>{article.title}</h1>
      <div style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, borderTop: `1px solid ${T.rule}`, borderBottom: `1px solid ${T.rule}`, padding: "10px 0" }}>
        <strong style={{ color: T.ink }}>{article.authorNames}</strong>{article.affiliation ? ` · ${article.affiliation}` : ""}<br />
        Submitted by {article.submittedBy.name} ({article.submittedBy.email})
      </div>

      <div style={{ background: T.faint, borderLeft: `3px solid ${T.ink}`, padding: "14px 18px", margin: "22px 0" }}>
        <Eyebrow>Abstract</Eyebrow>
        <p style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.55, color: "#222", margin: "8px 0 0" }}>{article.abstract}</p>
      </div>

      <div className="body" dangerouslySetInnerHTML={{ __html: article.bodyHtml }} />

      <div style={box}>
        <Eyebrow>Reviews ({article.reviews.length})</Eyebrow>
        {article.reviews.length === 0 ? (
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "10px 0 0" }}>No reviews recorded yet.</p>
        ) : article.reviews.map((r) => (
          <div key={r.id} style={{ borderTop: `1px solid ${T.rule}`, paddingTop: 10, marginTop: 10 }}>
            <div style={{ fontFamily: T.sans, fontSize: 13 }}><strong>{r.editorName}</strong> · <span style={{ color: T.ink }}>{recLabel(r.recommendation)}</span></div>
            {r.comments && <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.55, color: "#333", margin: "6px 0 0" }}>{r.comments}</p>}
          </div>
        ))}
      </div>

      {!decided && (
        <form onSubmit={saveReview} style={box}>
          <Eyebrow>{myRecommendation ? "Update your review" : "Record your review"}</Eyebrow>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", margin: "12px 0" }}>
            {RECS.map(([v, label]) => (
              <label key={v} style={{ fontFamily: T.sans, fontSize: 13.5, display: "flex", alignItems: "center", gap: 6, cursor: "pointer" }}>
                <input type="radio" name="rec" value={v} checked={rec === v} onChange={() => setRec(v)} /> {label}
              </label>
            ))}
          </div>
          <textarea value={comments} onChange={(e) => setComments(e.target.value)} placeholder="Comments to the editor (optional)" style={{ ...input, width: "100%", minHeight: 90, resize: "vertical", fontFamily: T.serif }} />
          <div style={{ marginTop: 12 }}>
            <button type="submit" disabled={busy} style={{ padding: "10px 18px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Save review</button>
          </div>
        </form>
      )}

      {canDecide && !decided && (
        <div style={{ ...box, borderWidth: 2 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 9, color: T.ink }}><IconScale size={20} /><Eyebrow>Editor-in-Chief decision</Eyebrow></div>

          <div style={{ margin: "14px 0" }}>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Feedback to author (required to request a revision)</label>
            <textarea value={feedback} onChange={(e) => setFeedback(e.target.value)} placeholder="Summarise the changes the author should make…" style={{ ...input, width: "100%", minHeight: 80, resize: "vertical", fontFamily: T.serif, marginTop: 4 }} />
            <button onClick={() => decide("REVISE")} disabled={busy} style={{ marginTop: 8, padding: "9px 16px", background: T.paper, color: "#b26a00", border: "1px solid #b26a00", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Request revision</button>
          </div>

          <div style={{ borderTop: `1px solid ${T.rule}`, paddingTop: 14, display: "flex", gap: 12, flexWrap: "wrap", alignItems: "end" }}>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Issue<br />
              <select value={issueId} onChange={(e) => setIssueId(e.target.value)} style={{ ...input, marginTop: 4 }}>
                {issues.map((i) => <option key={i.id} value={i.id}>Vol {i.volume}, Issue {i.number} ({i.label}){i.isCurrent ? " · current" : ""}</option>)}
              </select>
            </label>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Start page<br /><input value={startPage} onChange={(e) => setStartPage(e.target.value)} inputMode="numeric" style={{ ...input, width: 90, marginTop: 4 }} /></label>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>End page<br /><input value={endPage} onChange={(e) => setEndPage(e.target.value)} inputMode="numeric" style={{ ...input, width: 90, marginTop: 4 }} /></label>
          </div>
          <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
            <button onClick={() => decide("PUBLISH")} disabled={busy} style={{ padding: "11px 20px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Publish</button>
            <button onClick={() => decide("REJECT")} disabled={busy} style={{ padding: "11px 20px", background: T.paper, color: "#b00020", border: "1px solid #b00020", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Reject</button>
          </div>
        </div>
      )}

      {article.status === "REVISION_REQUESTED" && <p style={{ fontFamily: T.sans, fontSize: 13.5, color: "#b26a00" }}>Revision requested — awaiting the author&rsquo;s resubmission.</p>}
      {decided && <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted }}>This manuscript has been <strong style={{ color: T.ink }}>{article.status.toLowerCase()}</strong>.</p>}
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg.includes("saved") ? "#1a7f37" : "#b00020", marginTop: 12 }}>{msg}</p>}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- editor detail page (pass revisionCount)
cat > "src/app/editor/[id]/page.tsx" << 'IJRI_EOF'
import { redirect, notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";
import ReviewDesk from "./ReviewDesk";

export const dynamic = "force-dynamic";

export default async function SubmissionDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");

  const a = await prisma.article.findUnique({
    where: { id },
    include: {
      section: { select: { name: true } }, issue: { select: { id: true } },
      submittedBy: { select: { name: true, email: true, affiliation: true } },
      reviews: { include: { editor: { select: { id: true, name: true } } }, orderBy: { createdAt: "asc" } },
    },
  });
  if (!a) notFound();
  const issues = await prisma.issue.findMany({ orderBy: [{ volume: "desc" }, { number: "desc" }], select: { id: true, volume: true, number: true, label: true, isCurrent: true } });

  const article = {
    id: a.id, title: a.title, abstract: a.abstract, bodyHtml: sanitize(a.bodyHtml ?? ""), authorNames: a.authorNames,
    affiliation: a.affiliation, status: a.status, section: a.section.name, submittedBy: a.submittedBy,
    issueId: a.issue?.id ?? null, startPage: a.startPage, endPage: a.endPage, revisionCount: a.revisionCount,
    reviews: a.reviews.map((r) => ({ id: r.id, editorId: r.editor.id, editorName: r.editor.name, recommendation: r.recommendation, comments: r.comments })),
  };
  const myReview = article.reviews.find((r) => r.editorId === acc.id) ?? null;

  return <ReviewDesk me={{ id: acc.id, role: acc.role }} article={article} issues={issues} myRecommendation={myReview?.recommendation ?? null} myComments={myReview?.comments ?? ""} />;
}
IJRI_EOF

# ---------------------------------------------------------------- author: my submissions + resubmit
cat > src/app/my-submissions/page.tsx << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { T, Eyebrow, Chip } from "@/lib/ui";
import { IconDoc } from "@/lib/icons";
import ResubmitForm from "./ResubmitForm";

export const dynamic = "force-dynamic";

const LABEL: Record<string, string> = { SUBMITTED: "Submitted", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", REVISION_REQUESTED: "Revision requested", PUBLISHED: "Published", REJECTED: "Rejected" };

export default async function MySubmissions() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const subs = await prisma.article.findMany({
    where: { submittedById: acc.id },
    include: { section: { select: { name: true } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>My submissions</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 16px" }}>My submissions</h1>
      {subs.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted }}>You haven&rsquo;t submitted any manuscripts yet.</p>
      ) : subs.map((a) => (
        <div key={a.id} style={{ borderTop: `1px solid ${T.rule}`, padding: "20px 0" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
            <Chip>{LABEL[a.status] ?? a.status}</Chip><span style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.section.name}</span>
          </div>
          <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 20, margin: "8px 0 4px" }}>{a.title}</h3>
          {a.status === "REVISION_REQUESTED" && (
            <div style={{ marginTop: 10 }}>
              <div style={{ background: "#fff8ec", border: "1px solid #e6c98a", padding: "12px 14px", marginBottom: 12 }}>
                <div style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", color: "#8a5a00", marginBottom: 4 }}>Editor feedback</div>
                <p style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.55, color: "#333", margin: 0 }}>{a.editorFeedback}</p>
              </div>
              <ResubmitForm article={{ id: a.id, title: a.title, abstract: a.abstract, bodyHtml: a.bodyHtml ?? "" }} />
            </div>
          )}
          {a.status === "PUBLISHED" && <a href={`/articles/${a.id}`} style={{ fontFamily: T.sans, fontSize: 13, textDecoration: "underline" }}>View published article →</a>}
        </div>
      ))}
    </main>
  );
}
IJRI_EOF

cat > src/app/my-submissions/ResubmitForm.tsx << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T } from "@/lib/ui";

export default function ResubmitForm({ article }: { article: { id: string; title: string; abstract: string; bodyHtml: string } }) {
  const [title, setTitle] = useState(article.title);
  const [abstract, setAbstract] = useState(article.abstract);
  const [bodyHtml, setBodyHtml] = useState(article.bodyHtml);
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setErr("");
    const r = await fetch(`/api/submissions/${article.id}/resubmit`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ title, abstract, bodyHtml }) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setErr(d.error ?? "Could not resubmit"); return; }
    router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "9px 11px", border: `1px solid ${T.ink}`, marginTop: 4, background: T.paper };

  if (!open) return <button onClick={() => setOpen(true)} style={{ padding: "9px 16px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Revise & resubmit</button>;

  return (
    <form onSubmit={submit} style={{ border: `1px solid ${T.ink}`, padding: "16px 18px" }}>
      <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Title<input style={input} value={title} onChange={(e) => setTitle(e.target.value)} required /></label>
      <div style={{ height: 12 }} />
      <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Abstract<textarea style={{ ...input, minHeight: 80, resize: "vertical" }} value={abstract} onChange={(e) => setAbstract(e.target.value)} required /></label>
      <div style={{ height: 12 }} />
      <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Manuscript body<textarea style={{ ...input, minHeight: 180, resize: "vertical", fontFamily: T.serif }} value={bodyHtml} onChange={(e) => setBodyHtml(e.target.value)} required /></label>
      {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{err}</p>}
      <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
        <button type="submit" disabled={busy} style={{ padding: "10px 18px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Resubmit</button>
        <button type="button" onClick={() => setOpen(false)} style={{ padding: "10px 18px", background: T.paper, color: T.ink, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Cancel</button>
      </div>
    </form>
  );
}
IJRI_EOF

echo ""
echo "Revision loop written. Now run:  npx prisma db push  (adds revision fields + events)"
