#!/usr/bin/env bash
# ==========================================================================
# IJRI — review desk details + editor assignment (#4 / #7).
#   queue rows: author name, submission date & time, section, status, counts
#   detail: assign editors (min 2, more allowed) + "Send for review" button
# Run in repo:  bash build-reviewqueue.sh  ->  npm run build
#   (schema already has ReviewAssignment from build-profile2.sh)
# ==========================================================================
set -euo pipefail
echo "Review desk details + assignment..."

BASE="src/app"
[ -d "src/app/(backend)" ] && BASE="src/app/(backend)"
mkdir -p "$BASE/editor/[id]" "src/app/api/submissions/[id]/assign"
echo "  editor pages -> $BASE/editor"

# ---------------------------------------------------------------- queue with author + date/time
cat > "$BASE/editor/page.tsx" << 'IJRI_EOF'
import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconDoc, IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

const STATUS_LABEL: Record<string, string> = { SUBMITTED: "New", UNDER_REVIEW: "Under review", REVIEWED: "Reviewed", REVISION_REQUESTED: "Revision", PUBLISHED: "Published", REJECTED: "Rejected" };

export default async function EditorQueue() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/dashboard");

  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED", "REVISION_REQUESTED"] } },
    include: { section: { select: { name: true } }, submittedBy: { select: { name: true } }, reviews: { select: { id: true } }, assignments: { select: { id: true } } },
    orderBy: { createdAt: "asc" },
  });
  const recent = await prisma.article.findMany({ where: { status: { in: ["PUBLISHED", "REJECTED"] } }, orderBy: { decidedAt: "desc" }, take: 6, select: { id: true, title: true, status: true } });

  const fmt = (d: Date) => new Date(d).toLocaleString(undefined, { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>Editorial Desk</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 4px" }}>Submission queue</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 16px" }}>Signed in as {acc.name}</p>

      {queue.length === 0 ? (
        <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted }}>No manuscripts are awaiting action.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.ink}` }}>
          {queue.map((a) => (
            <Link key={a.id} href={`/editor/${a.id}`} style={{ display: "grid", gridTemplateColumns: "1fr auto", gap: 12, alignItems: "center", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ minWidth: 0 }}>
                <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 18, lineHeight: 1.25 }}>{a.title}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.ink, marginTop: 3 }}>{a.authorNames}</div>
                <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 2 }}>
                  {a.section.name} · submitted {fmt(a.createdAt)} by {a.submittedBy.name} · {a.assignments.length} editor{a.assignments.length === 1 ? "" : "s"} · {a.reviews.length} review{a.reviews.length === 1 ? "" : "s"}
                </div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.05em", textTransform: "uppercase", color: T.paper, background: a.status === "SUBMITTED" ? "#b26a00" : T.ink, padding: "3px 8px", whiteSpace: "nowrap" }}>{STATUS_LABEL[a.status]}</span>
                <IconArrow size={16} />
              </div>
            </Link>
          ))}
        </div>
      )}

      {recent.length > 0 && (
        <>
          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, margin: "34px 0 0", borderBottom: `1px solid ${T.rule}`, paddingBottom: 8 }}>Recent decisions</h2>
          {recent.map((a) => (
            <div key={a.id} style={{ display: "flex", justifyContent: "space-between", padding: "11px 4px", borderBottom: `1px solid ${T.rule}`, fontFamily: T.sans, fontSize: 13 }}>
              <span style={{ color: T.ink }}>{a.title}</span>
              <span style={{ color: a.status === "PUBLISHED" ? "#1a7f37" : "#b00020", textTransform: "uppercase", fontSize: 11 }}>{STATUS_LABEL[a.status]}</span>
            </div>
          ))}
        </>
      )}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- assignment API
cat > "src/app/api/submissions/[id]/assign/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");

  const b = await req.json().catch(() => null);
  const action = String(b?.action ?? "");

  if (action === "add") {
    const editorId = String(b?.editorId ?? "");
    if (!editorId) return Response.json({ error: "Choose an editor" }, { status: 400 });
    await prisma.reviewAssignment.upsert({ where: { articleId_editorId: { articleId: id, editorId } }, update: {}, create: { articleId: id, editorId } });
    return Response.json({ ok: true });
  }
  if (action === "send") {
    const count = await prisma.reviewAssignment.count({ where: { articleId: id } });
    if (count < 2) return Response.json({ error: "Assign at least two editors first" }, { status: 400 });
    await prisma.article.update({ where: { id }, data: { status: "UNDER_REVIEW" } });
    return Response.json({ ok: true });
  }
  return Response.json({ error: "Unknown action" }, { status: 400 });
}

export async function DELETE(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");
  const b = await req.json().catch(() => null);
  const editorId = String(b?.editorId ?? "");
  await prisma.reviewAssignment.deleteMany({ where: { articleId: id, editorId } });
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- AssignPanel (client)
cat > "$BASE/editor/[id]/AssignPanel.tsx" << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type E = { id: string; name: string };

export default function AssignPanel({ articleId, status, assigned, editors }: { articleId: string; status: string; assigned: { editorId: string; name: string }[]; editors: E[] }) {
  const router = useRouter();
  const [pick, setPick] = useState("");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");

  const assignedIds = new Set(assigned.map((a) => a.editorId));
  const available = editors.filter((e) => !assignedIds.has(e.id));

  async function call(method: string, body: Record<string, unknown>) {
    setBusy(true); setMsg("");
    const r = await fetch(`/api/submissions/${articleId}/assign`, { method, headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Failed"); return; }
    router.refresh();
  }

  const canSend = assigned.length >= 2 && status === "SUBMITTED";
  const chip: React.CSSProperties = { display: "inline-flex", alignItems: "center", gap: 6, fontFamily: T.sans, fontSize: 13, border: `1px solid ${T.ink}`, padding: "5px 10px" };

  return (
    <div style={{ border: `1px solid ${T.ink}`, padding: "14px 16px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 9, color: T.ink }}><IconUsers size={18} /><Eyebrow>Assigned editors ({assigned.length})</Eyebrow></div>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap", margin: "10px 0" }}>
        {assigned.length === 0 && <span style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>None yet — assign at least two.</span>}
        {assigned.map((a) => (
          <span key={a.editorId} style={chip}>{a.name}
            <button onClick={() => call("DELETE", { editorId: a.editorId })} disabled={busy} title="Remove" style={{ background: "none", border: "none", cursor: "pointer", color: "#b00020", fontSize: 14, padding: 0, lineHeight: 1 }}>×</button>
          </span>
        ))}
      </div>

      <div style={{ display: "flex", gap: 8, flexWrap: "wrap", alignItems: "center" }}>
        <select value={pick} onChange={(e) => setPick(e.target.value)} style={{ fontFamily: T.sans, fontSize: 13, padding: "8px 10px", border: `1px solid ${T.ink}`, background: T.paper }}>
          <option value="">Add an editor…</option>
          {available.map((e) => <option key={e.id} value={e.id}>{e.name}</option>)}
        </select>
        <button onClick={() => pick && call("POST", { action: "add", editorId: pick })} disabled={busy || !pick} style={{ padding: "8px 14px", background: T.paper, color: T.ink, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", cursor: "pointer" }}>Add</button>

        {canSend && (
          <button onClick={() => call("POST", { action: "send" })} disabled={busy} style={{ marginLeft: "auto", padding: "9px 18px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Send for review →</button>
        )}
      </div>
      {status !== "SUBMITTED" && <p style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 8 }}>Status: {status.replace(/_/g, " ").toLowerCase()}.</p>}
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", marginTop: 8 }}>{msg}</p>}
    </div>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- editor detail (history + assign + similarity + review)
cat > "$BASE/editor/[id]/page.tsx" << 'IJRI_EOF'
import { redirect, notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { sanitize } from "@/lib/sanitize";
import ReviewDesk from "./ReviewDesk";
import SimilarityPanel from "./SimilarityPanel";
import AssignPanel from "./AssignPanel";

export const dynamic = "force-dynamic";

export default async function SubmissionDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/dashboard");

  const a = await prisma.article.findUnique({
    where: { id },
    include: {
      section: { select: { name: true } }, issue: { select: { id: true } },
      submittedBy: { select: { name: true, email: true, affiliation: true } },
      reviews: { include: { editor: { select: { id: true, name: true } } }, orderBy: { createdAt: "asc" } },
      assignments: { select: { editorId: true } },
    },
  });
  if (!a) notFound();

  const issues = await prisma.issue.findMany({ orderBy: [{ volume: "desc" }, { number: "desc" }], select: { id: true, volume: true, number: true, label: true, isCurrent: true } });
  const editors = await prisma.user.findMany({ where: { role: { in: ["EDITOR", "CHIEF_EDITOR"] }, approved: true }, select: { id: true, name: true }, orderBy: { name: "asc" } });
  const nameOf = Object.fromEntries(editors.map((e) => [e.id, e.name]));
  const assigned = a.assignments.map((x) => ({ editorId: x.editorId, name: nameOf[x.editorId] ?? "Unknown editor" }));

  const article = {
    id: a.id, title: a.title, abstract: a.abstract, bodyHtml: sanitize(a.bodyHtml ?? ""), authorNames: a.authorNames,
    affiliation: a.affiliation, status: a.status, section: a.section.name, submittedBy: a.submittedBy,
    issueId: a.issue?.id ?? null, startPage: a.startPage, endPage: a.endPage, revisionCount: a.revisionCount,
    reviews: a.reviews.map((r) => ({ id: r.id, editorId: r.editor.id, editorName: r.editor.name, recommendation: r.recommendation, comments: r.comments })),
  };
  const myReview = article.reviews.find((r) => r.editorId === acc.id) ?? null;

  return (
    <>
      <div style={{ maxWidth: 760, margin: "0 auto", padding: "16px 20px 0", display: "flex", gap: 14 }}>
        <a href={`/history/${a.id}`} style={{ fontFamily: "ui-sans-serif, system-ui, sans-serif", fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", textDecoration: "underline" }}>Edit history →</a>
      </div>
      <div style={{ maxWidth: 760, margin: "0 auto", padding: "12px 20px 0" }}><AssignPanel articleId={a.id} status={a.status} assigned={assigned} editors={editors} /></div>
      <div style={{ maxWidth: 760, margin: "0 auto", padding: "12px 20px 0" }}><SimilarityPanel articleId={a.id} /></div>
      <ReviewDesk me={{ id: acc.id, role: acc.role }} article={article} issues={issues} myRecommendation={myReview?.recommendation ?? null} myComments={myReview?.comments ?? ""} />
    </>
  );
}
IJRI_EOF

echo ""
echo "Review desk updated. Now run:  npm run build"
