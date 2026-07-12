"use client";
import { useEffect, useState } from "react";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers, IconLayers, IconDoc } from "@/lib/icons";

type U = { id: string; name: string; email: string; role: string; approved: boolean; affiliation?: string | null };
type S = { id: string; name: string; slug: string; _count: { articles: number } };
type Q = { id: string; title: string; status: string; section: { name: string }; submittedBy: { name: string }; reviews: { id: string }[] };

const canAdmin = (role: string) => role === "ADMIN" || role === "CHIEF_EDITOR";

export default function AdminPanel({ me }: { me: { name: string; role: string } }) {
  const [users, setUsers] = useState<U[]>([]);
  const [sections, setSections] = useState<S[]>([]);
  const [queue, setQueue] = useState<Q[]>([]);
  const [newSection, setNewSection] = useState("");
  const [msg, setMsg] = useState("");

  async function load() {
    const [u, s, q] = await Promise.all([
      fetch("/api/admin/users").then((r) => r.json()),
      fetch("/api/admin/sections").then((r) => r.json()),
      fetch("/api/submissions").then((r) => r.json()),
    ]);
    setUsers(Array.isArray(u) ? u : []);
    setSections(Array.isArray(s) ? s : []);
    setQueue(Array.isArray(q) ? q : []);
  }
  useEffect(() => { load(); }, []);

  async function setApproved(id: string, approved: boolean) {
    await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId: id, approved }) });
    load();
  }
  async function setRole(id: string, role: string) {
    await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId: id, role }) });
    load();
  }
  async function addSection() {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name: newSection }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not add section"); return; }
    setNewSection(""); load();
  }
  async function delSection(id: string) {
    setMsg("");
    const r = await fetch("/api/admin/sections", { method: "DELETE", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ id }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not delete section"); return; }
    load();
  }

  const H = ({ icon, children }: { icon: React.ReactNode; children: React.ReactNode }) => (
    <div style={{ display: "flex", alignItems: "center", gap: 9, margin: "34px 0 4px", color: T.ink }}>
      {icon}<h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", margin: 0, borderBottom: `2px solid ${T.ink}`, paddingBottom: 6, flex: 1 }}>{children}</h2>
    </div>
  );
  const btn = (bg: string, color: string): React.CSSProperties => ({ background: bg, color, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.04em", textTransform: "uppercase", padding: "5px 10px", cursor: "pointer" });

  return (
    <main style={{ maxWidth: 980, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Admin</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "12px 0 4px" }}>Editorial administration</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>Signed in as {me.name} · {me.role}</p>
      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}

      <H icon={<IconUsers size={18} />}>Users &amp; access</H>
      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse", fontFamily: T.sans, fontSize: 13 }}>
          <thead><tr style={{ textAlign: "left", color: T.muted, fontSize: 11, textTransform: "uppercase", letterSpacing: "0.06em" }}>
            <th style={{ padding: "8px 6px" }}>Name</th><th>Email</th><th>Role</th><th>Status</th><th></th>
          </tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} style={{ borderTop: `1px solid ${T.rule}` }}>
                <td style={{ padding: "9px 6px" }}>{u.name}</td>
                <td style={{ color: T.muted }}>{u.email}</td>
                <td>{u.role}</td>
                <td style={{ color: u.approved ? "#1a7f37" : "#b26a00" }}>{u.approved ? "Approved" : "Pending"}</td>
                <td style={{ display: "flex", gap: 6, padding: "7px 0", flexWrap: "wrap" }}>
                  {canAdmin(me.role) && (u.approved
                    ? <button style={btn(T.paper, T.ink)} onClick={() => setApproved(u.id, false)}>Revoke</button>
                    : <button style={btn(T.ink, T.paper)} onClick={() => setApproved(u.id, true)}>Approve</button>)}
                  {canAdmin(me.role) && u.role === "AUTHOR" && <button style={btn(T.paper, T.ink)} onClick={() => setRole(u.id, "EDITOR")}>Make editor</button>}
                  {canAdmin(me.role) && u.role === "EDITOR" && <button style={btn(T.paper, T.ink)} onClick={() => setRole(u.id, "AUTHOR")}>Make author</button>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <H icon={<IconLayers size={18} />}>Sections</H>
      <div style={{ display: "flex", gap: 8, margin: "6px 0 14px" }}>
        <input value={newSection} onChange={(e) => setNewSection(e.target.value)} placeholder="New section name" style={{ flex: 1, maxWidth: 320, fontFamily: T.sans, fontSize: 14, padding: "8px 10px", border: `1px solid ${T.ink}` }} />
        <button style={btn(T.ink, T.paper)} onClick={addSection}>Add</button>
      </div>
      <div style={{ borderTop: `1px solid ${T.rule}` }}>
        {sections.map((s) => (
          <div key={s.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 4px", borderBottom: `1px solid ${T.rule}`, fontFamily: T.sans, fontSize: 14 }}>
            <span>{s.name} <span style={{ color: T.muted, fontSize: 12 }}>· {s._count.articles} article(s)</span></span>
            {me.role === "ADMIN" && <button style={btn(T.paper, T.ink)} onClick={() => delSection(s.id)} disabled={s._count.articles > 0}>Remove</button>}
          </div>
        ))}
      </div>

      <H icon={<IconDoc size={18} />}>Submission queue</H>
      {queue.length === 0 ? (
        <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted }}>No submissions awaiting review.</p>
      ) : (
        <div style={{ borderTop: `1px solid ${T.rule}` }}>
          {queue.map((q) => (
            <div key={q.id} style={{ padding: "12px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ fontFamily: T.serif, fontSize: 17 }}>{q.title}</div>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{q.section.name} · by {q.submittedBy.name} · {q.status} · {q.reviews.length} review(s)</div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
