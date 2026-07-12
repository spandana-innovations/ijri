#!/usr/bin/env bash
# ==========================================================================
# IJRI — editorial workflow UI (the reviewer desk + EIC decision screen).
#   /editor            : submission queue (staff)
#   /editor/[id]       : read manuscript, record review, publish or reject
# Uses the existing /api/submissions/[id]/reviews and .../decision routes.
# Run in repo:  bash build-editor.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Editorial desk..."
mkdir -p src/app/editor "src/app/editor/[id]"

# ---------------------------------------------------------------- queue
cat > src/app/editor/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconDoc, IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<string, string> = {
  SUBMITTED: "New", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", PUBLISHED: "Published", REJECTED: "Rejected",
};

export default async function EditorQueue() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");

  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  const recent = await prisma.article.findMany({
    where: { status: { in: ["PUBLISHED", "REJECTED"] } },
    include: { section: { select: { name: true } } },
    orderBy: { decidedAt: "desc" }, take: 6,
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>Editorial Desk</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 4px" }}>Submission queue</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 8px" }}>
        Signed in as {acc.name} · {acc.role === "CHIEF_EDITOR" || acc.role === "ADMIN" ? "you can record reviews and publish decisions" : "you can record reviews"}
        {" · "}<Link href="/admin" style={{ textDecoration: "underline" }}>Admin</Link>
      </p>

      {queue.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted, marginTop: 20 }}>No manuscripts are awaiting action.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.ink}`, marginTop: 14 }}>
          {queue.map((a) => (
            <Link key={a.id} href={`/editor/${a.id}`} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 12, alignItems: "center", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div>
                <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 18, lineHeight: 1.25 }}>{a.title}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{a.section.name} · by {a.submittedBy.name} · {a.reviews.length} review(s)</div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.paper, background: a.status === "SUBMITTED" ? "#b26a00" : T.ink, padding: "3px 8px" }}>{STATUS_LABEL[a.status]}</span>
                <IconArrow size={16} />
              </div>
            </Link>
          ))}
        </div>
      )}

      {recent.length > 0 && (
        <>
          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, margin: "40px 0 0", borderBottom: `1px solid ${T.rule}`, paddingBottom: 8 }}>Recent decisions</h2>
          {recent.map((a) => (
            <div key={a.id} style={{ display: "flex", justifyContent: "space-between", padding: "11px 4px", borderBottom: `1px solid ${T.rule}`, fontFamily: T.sans, fontSize: 13 }}>
              <span style={{ color: T.ink }}>{a.title}</span>
              <span style={{ color: a.status === "PUBLISHED" ? "#1a7f37" : "#b00020", textTransform: "uppercase", fontSize: 11, letterSpacing: "0.06em" }}>{STATUS_LABEL[a.status]}</span>
            </div>
          ))}
        </>
      )}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- detail (server gate) -> ReviewDesk
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
      section: { select: { name: true } },
      issue: { select: { id: true } },
      submittedBy: { select: { name: true, email: true, affiliation: true } },
      reviews: { include: { editor: { select: { id: true, name: true } } }, orderBy: { createdAt: "asc" } },
    },
  });
  if (!a) notFound();

  const issues = await prisma.issue.findMany({
    orderBy: [{ volume: "desc" }, { number: "desc" }],
    select: { id: true, volume: true, number: true, label: true, isCurrent: true },
  });

  const article = {
    id: a.id, title: a.title, abstract: a.abstract, bodyHtml: sanitize(a.bodyHtml ?? ""),
    authorNames: a.authorNames, affiliation: a.affiliation, status: a.status,
    section: a.section.name, submittedBy: a.submittedBy,
    issueId: a.issue?.id ?? null, startPage: a.startPage, endPage: a.endPage,
    reviews: a.reviews.map((r) => ({
      id: r.id, editorId: r.editor.id, editorName: r.editor.name,
      recommendation: r.recommendation, comments: r.comments,
    })),
  };
  const myReview = article.reviews.find((r) => r.editorId === acc.id) ?? null;

  return (
    <ReviewDesk
      me={{ id: acc.id, role: acc.role }}
      article={article}
      issues={issues}
      myRecommendation={myReview?.recommendation ?? null}
      myComments={myReview?.comments ?? ""}
    />
  );
}
IJRI_EOF

# ---------------------------------------------------------------- ReviewDesk (client)
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
  issueId: string | null; startPage: number | null; endPage: number | null; reviews: Review[];
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
  const [msg, setMsg] = useState("");
  const [busy, setBusy] = useState(false);

  async function saveReview(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true); setMsg("");
    const r = await fetch(`/api/submissions/${article.id}/reviews`, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ recommendation: rec, comments }),
    });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save review"); return; }
    setMsg("Review saved."); router.refresh();
  }

  async function decide(decision: "PUBLISH" | "REJECT") {
    setBusy(true); setMsg("");
    const body: Record<string, unknown> = { decision };
    if (decision === "PUBLISH") {
      body.issueId = issueId || undefined;
      body.startPage = startPage ? Number(startPage) : undefined;
      body.endPage = endPage ? Number(endPage) : undefined;
    }
    const r = await fetch(`/api/submissions/${article.id}/decision`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
    });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not record decision"); return; }
    router.push("/editor"); router.refresh();
  }

  const box: React.CSSProperties = { border: `1px solid ${T.ink}`, padding: "18px 20px", margin: "22px 0" };
  const input: React.CSSProperties = { fontFamily: T.sans, fontSize: 14, padding: "9px 11px", border: `1px solid ${T.ink}`, background: T.paper };

  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "32px 20px 48px" }}>
      <Link href="/editor" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Back to queue</Link>

      <div style={{ marginTop: 16, display: "flex", gap: 8, alignItems: "center" }}>
        <Eyebrow inverse>{article.section}</Eyebrow>
        <Chip>{article.status.replace("_", " ")}</Chip>
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

      {/* existing reviews */}
      <div style={box}>
        <Eyebrow>Reviews ({article.reviews.length})</Eyebrow>
        {article.reviews.length === 0 ? (
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "10px 0 0" }}>No reviews recorded yet.</p>
        ) : (
          article.reviews.map((r) => (
            <div key={r.id} style={{ borderTop: `1px solid ${T.rule}`, paddingTop: 10, marginTop: 10 }}>
              <div style={{ fontFamily: T.sans, fontSize: 13 }}><strong>{r.editorName}</strong> · <span style={{ color: T.ink }}>{recLabel(r.recommendation)}</span></div>
              {r.comments && <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.55, color: "#333", margin: "6px 0 0" }}>{r.comments}</p>}
            </div>
          ))
        )}
      </div>

      {/* record my review */}
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

      {/* decision panel (chief / admin) */}
      {canDecide && !decided && (
        <div style={{ ...box, borderWidth: 2 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 9, color: T.ink }}><IconScale size={20} /><Eyebrow>Editor-in-Chief decision</Eyebrow></div>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap", alignItems: "end", margin: "14px 0" }}>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Issue<br />
              <select value={issueId} onChange={(e) => setIssueId(e.target.value)} style={{ ...input, marginTop: 4 }}>
                {issues.map((i) => <option key={i.id} value={i.id}>Vol {i.volume}, Issue {i.number} ({i.label}){i.isCurrent ? " · current" : ""}</option>)}
              </select>
            </label>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>Start page<br />
              <input value={startPage} onChange={(e) => setStartPage(e.target.value)} inputMode="numeric" style={{ ...input, width: 90, marginTop: 4 }} />
            </label>
            <label style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>End page<br />
              <input value={endPage} onChange={(e) => setEndPage(e.target.value)} inputMode="numeric" style={{ ...input, width: 90, marginTop: 4 }} />
            </label>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <button onClick={() => decide("PUBLISH")} disabled={busy} style={{ padding: "11px 20px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Publish</button>
            <button onClick={() => decide("REJECT")} disabled={busy} style={{ padding: "11px 20px", background: T.paper, color: "#b00020", border: "1px solid #b00020", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>Reject</button>
          </div>
        </div>
      )}

      {decided && <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted }}>This manuscript has been <strong style={{ color: T.ink }}>{article.status.toLowerCase()}</strong>.</p>}
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg.includes("saved") ? "#1a7f37" : "#b00020", marginTop: 12 }}>{msg}</p>}
    </main>
  );
}
IJRI_EOF

echo ""
echo "Editorial desk written. Now run:"
echo "  npm run build"
echo "  git add . && git commit -m 'Editorial desk: reviews + publish/reject' && git push origin main"
