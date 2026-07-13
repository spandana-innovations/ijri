"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T } from "@/lib/ui";
import { IconArrow } from "@/lib/icons";

type Plan = { id: string; name: string; price: string; period: string; note: string; section?: boolean };
const PLANS: Plan[] = [
  { id: "MONTHLY", name: "Monthly", price: "₹499", period: "per month", note: "Full digital access to all sections." },
  { id: "ANNUAL", name: "Annual", price: "₹3,999", period: "per year", note: "Best value — full digital access, save over monthly." },
  { id: "PRINT_DIGITAL", name: "Print + Digital", price: "₹5,999", period: "per year", note: "Printed issues mailed to you, plus full digital access." },
  { id: "SECTION", name: "Single section", price: "₹1,999", period: "per year", note: "Full access to one section of your choice.", section: true },
];

export default function SubscribeOptions({ sections }: { sections: { id: string; name: string }[] }) {
  const [busy, setBusy] = useState("");
  const [sectionId, setSectionId] = useState(sections[0]?.id ?? "");
  const [err, setErr] = useState("");
  const router = useRouter();

  async function activate(plan: Plan) {
    setBusy(plan.id); setErr("");
    const body: Record<string, unknown> = { plan: plan.id };
    if (plan.section) body.sectionId = sectionId;
    const r = await fetch("/api/subscribe", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
    setBusy("");
    if (!r.ok) { const d = await r.json().catch(() => ({})); setErr(d.error ?? "Could not activate"); return; }
    router.refresh();
  }

  return (
    <>
      {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020" }}>{err}</p>}
      <div className="cardgrid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 18 }}>
        {PLANS.map((p) => (
          <div key={p.id} style={{ border: p.id === "ANNUAL" ? `2px solid ${T.ink}` : `1px solid ${T.rule}`, padding: "22px 20px", display: "flex", flexDirection: "column" }}>
            <div style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.1em", textTransform: "uppercase", color: T.muted }}>{p.name}</div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 6, margin: "8px 0" }}>
              <span style={{ fontFamily: T.serif, fontSize: 34, fontWeight: 600 }}>{p.price}</span>
              <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>{p.period}</span>
            </div>
            <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.5, color: "#333", margin: "0 0 14px", flex: 1 }}>{p.note}</p>
            {p.section && (
              <select value={sectionId} onChange={(e) => setSectionId(e.target.value)} style={{ fontFamily: T.sans, fontSize: 13, padding: "8px 10px", border: `1px solid ${T.ink}`, marginBottom: 10 }}>
                {sections.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            )}
            <button onClick={() => activate(p)} disabled={busy === p.id} style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 8, padding: "12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer", opacity: busy === p.id ? 0.6 : 1 }}>
              {busy === p.id ? "Activating…" : <>Activate <IconArrow size={15} /></>}
            </button>
          </div>
        ))}
      </div>
      <p style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, marginTop: 18 }}>
        By subscribing you agree to the <a href="/terms" style={{ textDecoration: "underline" }}>Terms</a> and <a href="/refunds" style={{ textDecoration: "underline" }}>Refund Policy</a>.
      </p>
    </>
  );
}
