"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconFeather, IconInfo } from "@/lib/icons";

export default function WordSubmit({ sections, defaultAuthor, defaultAffiliation }:
  { sections: { id: string; name: string }[]; defaultAuthor: string; defaultAffiliation: string }) {
  const router = useRouter();
  const previewRef = useRef<HTMLDivElement>(null);

  const [fileName, setFileName] = useState("");
  const [loaded, setLoaded] = useState(false);
  const [progress, setProgress] = useState(0);
  const [stage, setStage] = useState("");
  const [removedImages, setRemovedImages] = useState(0);

  const [title, setTitle] = useState("");
  const [abstract, setAbstract] = useState("");
  const [authorNames, setAuthorNames] = useState(defaultAuthor);
  const [affiliation, setAffiliation] = useState(defaultAffiliation);
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? "");

  const [submitting, setSubmitting] = useState(false);
  const [err, setErr] = useState("");

  async function handleFile(file: File) {
    setErr(""); setLoaded(false); setProgress(0);
    if (!file.name.toLowerCase().endsWith(".docx")) { setErr("Please upload a .docx file (Word). Older .doc files aren't supported — save as .docx first."); return; }
    setFileName(file.name);

    // staged progress while we read + convert (mammoth gives no progress events)
    setStage("Reading document…"); setProgress(8);
    let pct = 8;
    const tick = setInterval(() => { pct = Math.min(88, pct + 4); setProgress(pct); }, 120);

    try {
      const arrayBuffer = await file.arrayBuffer();
      setStage("Converting…");
      const mod: any = await import("mammoth/mammoth.browser");
      const mammoth = mod.default ?? mod;
      const result = await mammoth.convertToHtml({ arrayBuffer });
      let html: string = result?.value ?? "";

      setStage("Formatting to journal style…");
      const imgs = (html.match(/<img/gi) ?? []).length;
      setRemovedImages(imgs);
      html = html.replace(/<img[^>]*>/gi, ""); // strip inline images (re-add figures in the editor)

      // try to lift a title from the first heading, and clean it out of the body
      const m = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i) ?? html.match(/<h2[^>]*>([\s\S]*?)<\/h2>/i);
      if (m) { const t = m[1].replace(/<[^>]+>/g, "").trim(); if (t && !title) setTitle(t); }

      clearInterval(tick); setProgress(100); setStage("Ready to review");
      if (previewRef.current) previewRef.current.innerHTML = html || "<p>(No text found in the document.)</p>";
      setLoaded(true);
    } catch (e) {
      clearInterval(tick); setProgress(0); setStage("");
      setErr("Could not read that file. Make sure it's a valid .docx.");
    }
  }

  async function submit() {
    setErr("");
    const bodyHtml = previewRef.current?.innerHTML ?? "";
    if (!title.trim() || !abstract.trim() || !sectionId || !bodyHtml.trim()) { setErr("Title, abstract, section, and manuscript body are all required."); return; }
    setSubmitting(true);
    const r = await fetch("/api/submissions/word", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, abstract, authorNames, affiliation, sectionId, bodyHtml }),
    });
    setSubmitting(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setErr(d.error ?? "Submission failed."); return; }
    router.push("/my-submissions"); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };

  return (
    <main style={{ maxWidth: 780, margin: "0 auto", padding: "40px 20px 60px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconFeather size={22} /><Eyebrow inverse>Submit from Word</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 6px" }}>Upload a Word document</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 20px" }}>
        Upload your .docx manuscript. We&rsquo;ll convert it into the journal&rsquo;s house style so you can review and edit it before submitting.
      </p>

      {/* dropzone */}
      <label style={{ display: "block", border: `2px dashed ${T.g300}`, background: T.g50, padding: "28px 20px", textAlign: "center", cursor: "pointer" }}
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => { e.preventDefault(); const f = e.dataTransfer.files?.[0]; if (f) handleFile(f); }}>
        <input type="file" accept=".docx" style={{ display: "none" }} onChange={(e) => { const f = e.target.files?.[0]; if (f) handleFile(f); }} />
        <div style={{ fontFamily: T.sans, fontSize: 14, color: T.ink }}>{fileName ? <strong>{fileName}</strong> : "Click to choose, or drag a .docx here"}</div>
        <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 4 }}>Word .docx only · max ~10&nbsp;MB recommended</div>
      </label>

      {/* progress indicator */}
      {progress > 0 && progress < 100 && (
        <div style={{ marginTop: 16 }}>
          <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginBottom: 6, display: "flex", justifyContent: "space-between" }}><span>{stage}</span><span>{progress}%</span></div>
          <div style={{ height: 8, background: T.g200, overflow: "hidden" }}><div style={{ height: "100%", width: `${progress}%`, background: T.ink, transition: "width .12s linear" }} /></div>
        </div>
      )}

      {loaded && (
        <>
          {removedImages > 0 && (
            <div style={{ display: "flex", gap: 9, alignItems: "flex-start", marginTop: 16, background: "#fff8ec", border: "1px solid #e6c98a", padding: "12px 14px" }}>
              <IconInfo size={18} />
              <p style={{ fontFamily: T.sans, fontSize: 12.5, lineHeight: 1.5, color: "#8a5a00", margin: 0 }}>{removedImages} image{removedImages === 1 ? "" : "s"} were removed during import. You can re-insert figures once the manuscript is accepted, or describe them in the text for now.</p>
            </div>
          )}

          <div style={{ marginTop: 24, display: "grid", gap: 16 }}>
            <div><span style={label}>Title</span><input style={input} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Manuscript title" /></div>
            <div><span style={label}>Abstract</span><textarea style={{ ...input, minHeight: 90, resize: "vertical", fontFamily: T.serif }} value={abstract} onChange={(e) => setAbstract(e.target.value)} placeholder="A concise summary of purpose, method, findings, and conclusions." /></div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
              <div><span style={label}>Author(s)</span><input style={input} value={authorNames} onChange={(e) => setAuthorNames(e.target.value)} /></div>
              <div><span style={label}>Affiliation</span><input style={input} value={affiliation} onChange={(e) => setAffiliation(e.target.value)} /></div>
            </div>
            <div><span style={label}>Section</span>
              <select style={input} value={sectionId} onChange={(e) => setSectionId(e.target.value)}>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
          </div>

          <div style={{ marginTop: 24 }}>
            <span style={label}>Manuscript body — edit directly below</span>
            <div ref={previewRef} contentEditable suppressContentEditableWarning className="body"
              style={{ border: `1px solid ${T.ink}`, padding: "20px 22px", marginTop: 6, minHeight: 240, outline: "none", background: T.paper }} />
            <p style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 6 }}>Formatting matches the journal. Edit headings, paragraphs, and lists as needed before submitting.</p>
          </div>

          {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", marginTop: 12 }}>{err}</p>}
          <button onClick={submit} disabled={submitting} style={{ marginTop: 18, padding: "13px 26px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: submitting ? 0.6 : 1 }}>
            {submitting ? "Submitting…" : "Submit for review"}
          </button>
        </>
      )}

      {err && !loaded && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", marginTop: 12 }}>{err}</p>}
    </main>
  );
}
