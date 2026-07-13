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
