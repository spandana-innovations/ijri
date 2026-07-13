"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import mammoth from "mammoth/mammoth.browser";
import { T, Eyebrow } from "@/lib/ui";
import { IconDoc } from "@/lib/icons";

type Section = { id: string; name: string };

function extract(html: string, filename: string) {
  const doc = new DOMParser().parseFromString(html, "text/html");

  // title = first heading, else filename
  const h = doc.querySelector("h1, h2, h3");
  const title = (h?.textContent || "").trim() || filename.replace(/\.[^.]+$/, "");

  // abstract = text after an "Abstract" heading, else first paragraph
  let abstract = "";
  const heads = Array.from(doc.querySelectorAll("h1, h2, h3, h4, strong, b"));
  const abHead = heads.find((el) => /abstract/i.test(el.textContent || ""));
  if (abHead) {
    let n: Element | null = (abHead.closest("p") as Element | null)?.nextElementSibling ?? abHead.nextElementSibling;
    const parts: string[] = [];
    while (n && !/^H[1-4]$/.test(n.tagName)) {
      const t = (n.textContent || "").trim();
      if (t) parts.push(t);
      if (parts.length >= 3) break;
      n = n.nextElementSibling;
    }
    abstract = parts.join(" ");
  }
  if (!abstract) {
    const p = doc.querySelector("p");
    abstract = (p?.textContent || "").trim().slice(0, 800);
  }

  // body = everything (images included) so content is never blank
  const body = doc.body.innerHTML;
  return { title, abstract, body };
}

export default function WordUpload({ sections, defaultAuthor }: { sections: Section[]; defaultAuthor: string }) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [f, setF] = useState({ title: "", authorNames: defaultAuthor ?? "", affiliation: "", sectionId: sections[0]?.id ?? "", abstract: "", bodyHtml: "" });
  const [status, setStatus] = useState("");
  const [progress, setProgress] = useState(0);
  const [imgCount, setImgCount] = useState(0);
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");

  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => setF({ ...f, [k]: e.target.value });

  async function onFile(file?: File) {
    if (!file) return;
    setMsg(""); setStatus("Reading document…"); setProgress(25);
    try {
      const arrayBuffer = await file.arrayBuffer();
      setStatus("Converting (keeping images)…"); setProgress(55);
      const result = await mammoth.convertToHtml({ arrayBuffer }, {
        convertImage: mammoth.images.imgElement(async (image) => {
          const b64 = await image.read("base64");
          return { src: `data:${image.contentType};base64,${b64}` };
        }),
        styleMap: ["p[style-name='Title'] => h1:fresh", "p[style-name='Subtitle'] => h2:fresh"],
      });
      setProgress(85);
      const html = result.value || "";
      const { title, abstract, body } = extract(html, file.name);
      const images = (body.match(/<img/g) || []).length;
      setImgCount(images);
      setF((prev) => ({ ...prev, title: prev.title || title, abstract: abstract || prev.abstract, bodyHtml: body }));
      setProgress(100);
      setStatus(`Imported${images ? ` with ${images} image${images === 1 ? "" : "s"}` : ""}. Review below, then submit.`);
    } catch {
      setStatus(""); setMsg("Could not read that .docx file. Make sure it's a Word document.");
    }
  }

  async function submit() {
    if (!f.title.trim() || !f.abstract.trim() || !f.bodyHtml.trim() || !f.sectionId) { setMsg("Title, abstract, body and section are all required."); return; }
    setBusy(true); setMsg("");
    const r = await fetch("/api/submissions", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(f) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Submission failed."); return; }
    router.push("/my-submissions"); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconDoc size={22} /><Eyebrow inverse>Upload a Word document</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 6px" }}>Submit from Word</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 18px", maxWidth: 620 }}>Upload a .docx and we&rsquo;ll pull in the title, abstract, body text and any embedded images. Review everything before submitting.</p>

      <button onClick={() => fileRef.current?.click()} style={{ padding: "11px 20px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Choose .docx file</button>
      <input ref={fileRef} type="file" accept=".docx,application/vnd.openxmlformats-officedocument.wordprocessingml.document" style={{ display: "none" }} onChange={(e) => onFile(e.target.files?.[0])} />

      {progress > 0 && (
        <div style={{ marginTop: 14, maxWidth: 640 }}>
          <div style={{ height: 6, background: T.g200 }}><div style={{ height: "100%", width: `${progress}%`, background: T.ink, transition: "width .2s" }} /></div>
          <p style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 6 }}>{status}</p>
        </div>
      )}

      {f.bodyHtml && (
        <div style={{ display: "grid", gap: 14, maxWidth: 660, marginTop: 20 }}>
          <div><span style={label}>Title</span><input style={input} value={f.title} onChange={set("title")} /></div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
            <div><span style={label}>Author names</span><input style={input} value={f.authorNames} onChange={set("authorNames")} /></div>
            <div><span style={label}>Affiliation</span><input style={input} value={f.affiliation} onChange={set("affiliation")} /></div>
          </div>
          <div><span style={label}>Section</span>
            <select style={input} value={f.sectionId} onChange={set("sectionId")}>
              {sections.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
          <div><span style={label}>Abstract</span><textarea style={{ ...input, minHeight: 110, resize: "vertical", fontFamily: T.serif }} value={f.abstract} onChange={set("abstract")} /></div>

          <div>
            <span style={label}>Body preview {imgCount > 0 ? `· ${imgCount} image${imgCount === 1 ? "" : "s"} embedded` : ""}</span>
            <div className="body" style={{ border: `1px solid ${T.rule}`, padding: "16px 18px", marginTop: 6, maxHeight: 420, overflow: "auto", background: T.paper }} dangerouslySetInnerHTML={{ __html: f.bodyHtml }} />
          </div>

          {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}
          <button onClick={submit} disabled={busy} style={{ padding: "13px 26px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1, justifySelf: "start" }}>{busy ? "Submitting…" : "Submit manuscript"}</button>
        </div>
      )}
    </main>
  );
}
