"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";
import Avatar, { AVATAR_PRESETS } from "@/components/Avatar";

type U = { name: string; email: string; affiliation: string | null; designation: string | null; website: string | null; linkedin: string | null; twitter: string | null; scholar: string | null; bio: string | null; image: string | null; role: string };

async function toBlackAndWhite(file: File): Promise<string> {
  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = url; });
    const size = 400;
    const canvas = document.createElement("canvas"); canvas.width = size; canvas.height = size;
    const ctx = canvas.getContext("2d")!;
    const scale = Math.max(size / img.width, size / img.height);
    const w = img.width * scale, h = img.height * scale;
    ctx.drawImage(img, (size - w) / 2, (size - h) / 2, w, h);
    const data = ctx.getImageData(0, 0, size, size); const d = data.data;
    const contrast = 1.6, intercept = 128 * (1 - contrast);
    for (let i = 0; i < d.length; i += 4) {
      let g = 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2];
      g = Math.max(0, Math.min(255, g * contrast + intercept));
      d[i] = d[i + 1] = d[i + 2] = g;
    }
    ctx.putImageData(data, 0, 0);
    return canvas.toDataURL("image/jpeg", 0.72);
  } finally { URL.revokeObjectURL(url); }
}

export default function ProfileForm({ user }: { user: U }) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [image, setImage] = useState(user.image ?? "");
  const [f, setF] = useState({
    name: user.name ?? "", email: user.email ?? "", affiliation: user.affiliation ?? "", designation: user.designation ?? "",
    website: user.website ?? "", linkedin: user.linkedin ?? "", twitter: user.twitter ?? "", scholar: user.scholar ?? "", bio: user.bio ?? "",
  });
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });

  async function onFile(file?: File) {
    if (!file) return;
    setMsg("Processing photo…");
    try { setImage(await toBlackAndWhite(file)); setMsg(""); }
    catch { setMsg("Could not process that image."); }
  }

  async function save() {
    setBusy(true); setMsg("");
    const r = await fetch("/api/account/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ...f, image }) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save"); return; }
    setMsg("Saved."); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>My profile</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 18px" }}>My profile</h1>

      {/* avatar + picker */}
      <div style={{ display: "flex", gap: 18, alignItems: "flex-start", marginBottom: 24, flexWrap: "wrap" }}>
        <Avatar image={image} name={f.name} size={92} />
        <div style={{ flex: 1, minWidth: 240 }}>
          <button onClick={() => fileRef.current?.click()} style={{ padding: "9px 16px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", cursor: "pointer" }}>Upload photo</button>
          <input ref={fileRef} type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => onFile(e.target.files?.[0])} />
          <p style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, margin: "8px 0 10px" }}>Photos are converted to the journal&rsquo;s black-and-white house style. Prefer a symbol? Pick one:</p>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            {AVATAR_PRESETS.map((p) => {
              const val = p === "initials" ? "" : `preset:${p}`;
              const active = image === val;
              return (
                <button key={p} onClick={() => setImage(val)} title={p} style={{ border: active ? `2px solid ${T.ink}` : `1px solid ${T.rule}`, padding: 2, background: T.paper, cursor: "pointer" }}>
                  <Avatar image={val} name={f.name} size={40} />
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gap: 14, maxWidth: 640 }}>
        <div><span style={label}>Full name</span><input style={input} value={f.name} onChange={set("name")} /></div>
        <div><span style={label}>Email (your sign-in)</span><input style={input} type="email" value={f.email} onChange={set("email")} /></div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Place of work</span><input style={input} value={f.affiliation} onChange={set("affiliation")} placeholder="Institution / employer" /></div>
          <div><span style={label}>Designation</span><input style={input} value={f.designation} onChange={set("designation")} placeholder="e.g. Professor" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>LinkedIn</span><input style={input} value={f.linkedin} onChange={set("linkedin")} placeholder="https://linkedin.com/in/…" /></div>
          <div><span style={label}>X / Twitter</span><input style={input} value={f.twitter} onChange={set("twitter")} placeholder="https://x.com/…" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Google Scholar</span><input style={input} value={f.scholar} onChange={set("scholar")} placeholder="https://scholar.google.com/…" /></div>
          <div><span style={label}>Website</span><input style={input} value={f.website} onChange={set("website")} placeholder="https://" /></div>
        </div>
        <div><span style={label}>Short bio (text only)</span><textarea style={{ ...input, minHeight: 120, resize: "vertical", fontFamily: T.serif }} value={f.bio} onChange={set("bio")} placeholder="A few lines about your research and background." /></div>
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg === "Saved." ? "#1a7f37" : msg.includes("Process") ? T.muted : "#b00020", marginTop: 12 }}>{msg}</p>}
      <button onClick={save} disabled={busy} style={{ marginTop: 16, padding: "12px 24px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>{busy ? "Saving…" : "Save profile"}</button>
    </main>
  );
}
