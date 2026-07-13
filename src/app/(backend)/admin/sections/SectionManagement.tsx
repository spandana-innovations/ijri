"use client";
import { useEffect, useState } from "react";
import { T, Eyebrow } from "@/lib/ui";

type S = { id: string; name: string; slug: string; articles: number };

export default function SectionManagement() {
  const [sections, setSections] = useState<S[]>([]);
  const [name, setName] = useState("");
  const [msg, setMsg] = useState("");
  const [loading, setLoading] = useState(true);

  async function load() { setLoading(true); try { const r = await fetch("/api/admin/sections"); const d = await r.json(); setSections(d.sections ?? []); } catch { /* */ } setLoading(false); }
  useEffect(() => { load(); }, []);

  async function add() {
    if (!name.trim()) return; setMsg("");
    const r = await fetch("/api/admin/sections", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Failed"); return; }
    setName(""); load();
  }
  async function remove(id: string) {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Failed"); return; }
    load();
  }

  return (
    <main>
      <Eyebrow inverse>Section management</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 16px" }}>Sections</h1>

      <div style={{ display: "flex", gap: 10, marginBottom: 20, maxWidth: 480 }}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="New section name" onKeyDown={(e) => e.key === "Enter" && add()} style={{ flex: 1, fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, background: T.paper }} />
        <button onClick={add} style={{ padding: "10px 18px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Add</button>
      </div>
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}

      {loading ? <p style={{ fontFamily: T.serif, color: T.muted }}>Loading…</p> : sections.map((s) => (
        <div key={s.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "13px 0", borderBottom: `1px solid ${T.rule}` }}>
          <div>
            <span style={{ fontFamily: T.serif, fontSize: 18 }}>{s.name}</span>
            <span style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginLeft: 10 }}>{s.articles} article{s.articles === 1 ? "" : "s"}</span>
          </div>
          <button onClick={() => remove(s.id)} disabled={s.articles > 0} title={s.articles > 0 ? "Section has articles" : "Remove"} style={{ padding: "6px 12px", background: T.paper, color: s.articles > 0 ? T.muted : "#b00020", border: `1px solid ${s.articles > 0 ? T.rule : "#b00020"}`, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", cursor: s.articles > 0 ? "not-allowed" : "pointer" }}>Remove</button>
        </div>
      ))}
    </main>
  );
}
