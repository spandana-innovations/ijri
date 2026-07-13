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
