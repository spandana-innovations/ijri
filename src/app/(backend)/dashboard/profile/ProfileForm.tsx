"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type U = { name: string; email: string; affiliation: string | null; designation: string | null; orcid: string | null; website: string | null; bio: string | null; image: string | null; role: string };

export default function ProfileForm({ user }: { user: U }) {
  const router = useRouter();
  const [f, setF] = useState({
    name: user.name ?? "", email: user.email ?? "", affiliation: user.affiliation ?? "",
    designation: user.designation ?? "", orcid: user.orcid ?? "", website: user.website ?? "",
    bio: user.bio ?? "", image: user.image ?? "",
  });
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });

  async function save() {
    setBusy(true); setMsg("");
    const r = await fetch("/api/account/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(f) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save"); return; }
    setMsg("Saved."); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };
  const initials = (f.name || "?").split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase();

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>My profile</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 18px" }}>My profile</h1>

      <div style={{ display: "flex", gap: 16, alignItems: "center", marginBottom: 22 }}>
        {f.image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={f.image} alt="" style={{ width: 72, height: 72, objectFit: "cover", border: `1px solid ${T.rule}`, filter: "grayscale(1)" }} />
        ) : (
          <div style={{ width: 72, height: 72, background: T.ink, color: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 26 }}>{initials}</div>
        )}
        <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>Role: {user.role.replace("_", " ").toLowerCase()}</div>
      </div>

      <div style={{ display: "grid", gap: 14, maxWidth: 620 }}>
        <div><span style={label}>Full name</span><input style={input} value={f.name} onChange={set("name")} /></div>
        <div><span style={label}>Email (your sign-in)</span><input style={input} type="email" value={f.email} onChange={set("email")} /></div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Place of work</span><input style={input} value={f.affiliation} onChange={set("affiliation")} placeholder="Institution / employer" /></div>
          <div><span style={label}>Designation</span><input style={input} value={f.designation} onChange={set("designation")} placeholder="e.g. Professor" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>ORCID</span><input style={input} value={f.orcid} onChange={set("orcid")} placeholder="0000-0000-0000-0000" /></div>
          <div><span style={label}>Website</span><input style={input} value={f.website} onChange={set("website")} placeholder="https://" /></div>
        </div>
        <div><span style={label}>Photo URL</span><input style={input} value={f.image} onChange={set("image")} placeholder="https://…/photo.jpg" /></div>
        <div><span style={label}>Short bio</span><textarea style={{ ...input, minHeight: 110, resize: "vertical", fontFamily: T.serif }} value={f.bio} onChange={set("bio")} placeholder="A few lines about your research and background." /></div>
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg === "Saved." ? "#1a7f37" : "#b00020", marginTop: 12 }}>{msg}</p>}
      <button onClick={save} disabled={busy} style={{ marginTop: 16, padding: "12px 24px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>{busy ? "Saving…" : "Save profile"}</button>
    </main>
  );
}
