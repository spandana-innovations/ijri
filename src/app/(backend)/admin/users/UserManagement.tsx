"use client";
import { useEffect, useState } from "react";
import Link from "next/link";
import { T, Eyebrow, Chip } from "@/lib/ui";
import Avatar from "@/components/Avatar";

type U = { id: string; name: string; email: string; role: string; approved: boolean; affiliation: string | null; designation: string | null; image: string | null };

const TABS: [string, string][] = [["ADMIN", "Super admins"], ["CHIEF_EDITOR", "Chief editor"], ["EDITOR", "Editors"], ["AUTHOR", "Authors"]];
const ROLE_OPTS: [string, string][] = [["AUTHOR", "Author"], ["EDITOR", "Editor"], ["CHIEF_EDITOR", "Chief editor"], ["ADMIN", "Super admin"]];
const SUPER = "info@ijrein.org";

export default function UserManagement() {
  const [users, setUsers] = useState<U[]>([]);
  const [tab, setTab] = useState("AUTHOR");
  const [loading, setLoading] = useState(true);
  const [msg, setMsg] = useState("");

  async function load() { setLoading(true); try { const r = await fetch("/api/admin/users"); const d = await r.json(); setUsers(d.users ?? []); } catch { /* */ } setLoading(false); }
  useEffect(() => { load(); }, []);

  async function act(userId: string, body: Record<string, unknown>) {
    setMsg("");
    const r = await fetch("/api/admin/users", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId, ...body }) });
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Action failed"); return; }
    load();
  }

  const pending = users.filter((u) => !u.approved).length;
  const shown = users.filter((u) => u.role === tab);

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><Eyebrow inverse>User management</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 4px" }}>Users &amp; access</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "0 0 18px" }}>{users.length} users{pending > 0 ? ` · ${pending} awaiting approval` : ""} · one Chief Editor allowed</p>

      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", borderBottom: `1px solid ${T.ink}`, marginBottom: 16 }}>
        {TABS.map(([key, label]) => {
          const n = users.filter((u) => u.role === key).length;
          return (
            <button key={key} onClick={() => setTab(key)} style={{ fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.03em", textTransform: "uppercase", padding: "9px 13px", cursor: "pointer", border: "none", background: tab === key ? T.ink : "transparent", color: tab === key ? T.paper : T.ink }}>{label} ({n})</button>
          );
        })}
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{msg}</p>}
      {loading ? <p style={{ fontFamily: T.serif, color: T.muted }}>Loading…</p> : shown.length === 0 ? <p style={{ fontFamily: T.serif, color: T.muted }}>No users in this group.</p> : shown.map((u) => (
        <div key={u.id} style={{ display: "grid", gridTemplateColumns: "40px 1fr auto", gap: 12, alignItems: "center", padding: "14px 0", borderBottom: `1px solid ${T.rule}` }}>
          <Avatar image={u.image} name={u.name} size={40} />
          <div style={{ minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
              <Link href={`/people/${u.id}`} className="cardtitle" style={{ fontFamily: T.serif, fontSize: 17 }}>{u.name}</Link>
              {u.email === SUPER && <Chip>super admin</Chip>}
              {!u.approved && <Chip>pending</Chip>}
            </div>
            <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>{u.email}{u.designation ? ` · ${u.designation}` : ""}{u.affiliation ? ` · ${u.affiliation}` : ""}</div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap", justifyContent: "flex-end" }}>
            {!u.approved && <button onClick={() => act(u.id, { action: "approve" })} style={{ padding: "7px 12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", cursor: "pointer" }}>Approve</button>}
            <select value={u.role} disabled={u.email === SUPER} onChange={(e) => act(u.id, { action: "role", role: e.target.value })} style={{ fontFamily: T.sans, fontSize: 12.5, padding: "7px 8px", border: `1px solid ${T.ink}`, background: T.paper, opacity: u.email === SUPER ? 0.5 : 1 }}>
              {ROLE_OPTS.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
        </div>
      ))}
    </main>
  );
}
