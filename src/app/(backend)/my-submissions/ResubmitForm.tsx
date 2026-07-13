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
