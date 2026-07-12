"use client";
import { useState } from "react";
import Link from "next/link";
import { T, Eyebrow } from "@/lib/ui";
import { IconFeather } from "@/lib/icons";

export default function SubmitForm({ sections, authorName }: { sections: { id: string; name: string }[]; authorName: string }) {
  const [title, setTitle] = useState("");
  const [authors, setAuthors] = useState(authorName);
  const [affiliation, setAffiliation] = useState("");
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? "");
  const [abstract, setAbstract] = useState("");
  const [bodyHtml, setBodyHtml] = useState("");
  const [err, setErr] = useState("");
  const [done, setDone] = useState(false);
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const r = await fetch("/api/submissions", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, authorNames: authors, affiliation, sectionId, abstract, bodyHtml }),
    });
    setLoading(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setErr(d.error ?? "Submission failed"); return; }
    setDone(true);
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };
  const lbl: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted, display: "block", marginTop: 16 };

  if (done) {
    return (
      <main style={{ maxWidth: 620, margin: "60px auto", padding: "0 20px", textAlign: "center" }}>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30 }}>Submission received</h1>
        <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>Your manuscript has been submitted for double-blind peer review. You&rsquo;ll be notified as it moves through the editorial process.</p>
        <p style={{ marginTop: 20 }}><Link href="/" style={{ fontFamily: T.sans, fontSize: 13, textDecoration: "underline", textTransform: "uppercase", letterSpacing: "0.06em" }}>Back to the journal</Link></p>
      </main>
    );
  }

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconFeather size={22} /><Eyebrow inverse>Submit</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,36px)", margin: "12px 0 6px" }}>Submit a manuscript</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 10px" }}>Please review the <Link href="/for-authors" style={{ textDecoration: "underline", color: T.ink }}>author guidelines</Link> before submitting.</p>
      <form onSubmit={submit}>
        <label style={lbl}>Title<input style={input} value={title} onChange={(e) => setTitle(e.target.value)} required /></label>
        <label style={lbl}>Author(s)<input style={input} value={authors} onChange={(e) => setAuthors(e.target.value)} required /></label>
        <label style={lbl}>Affiliation<input style={input} value={affiliation} onChange={(e) => setAffiliation(e.target.value)} /></label>
        <label style={lbl}>Section
          <select style={input} value={sectionId} onChange={(e) => setSectionId(e.target.value)} required>
            {sections.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </label>
        <label style={lbl}>Abstract<textarea style={{ ...input, minHeight: 110, resize: "vertical" }} value={abstract} onChange={(e) => setAbstract(e.target.value)} required /></label>
        <label style={lbl}>Manuscript body (HTML or plain text)
          <textarea style={{ ...input, minHeight: 220, resize: "vertical", fontFamily: T.serif }} value={bodyHtml} onChange={(e) => setBodyHtml(e.target.value)} required />
        </label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ marginTop: 22, padding: "12px 22px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Submitting…" : "Submit for review"}
        </button>
      </form>
    </main>
  );
}
