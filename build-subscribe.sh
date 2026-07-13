#!/usr/bin/env bash
# ==========================================================================
# IJRI — subscribe / access flow. Activates real subscriptions so the paywall
# functions. NOTE: no charge is taken yet — this is "launch mode" until you
# wire a payment gateway (Razorpay/Stripe). The entitlement logic already
# reads these subscriptions, so full-text access works end to end.
# Run in repo:  bash build-subscribe.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Subscribe / access flow..."
mkdir -p src/app/subscribe src/app/api/subscribe

# ---------------------------------------------------------------- subscribe API
cat > src/app/api/subscribe/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized } from "@/lib/auth";
import type { PlanType } from "@prisma/client";

const PLANS: Record<PlanType, { days: number; print?: boolean }> = {
  MONTHLY: { days: 30 },
  ANNUAL: { days: 365 },
  PRINT_DIGITAL: { days: 365, print: true },
  SECTION: { days: 365 },
};

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  const b = await req.json().catch(() => null);
  const plan = String(b?.plan ?? "") as PlanType;
  if (!(plan in PLANS)) return Response.json({ error: "Invalid plan" }, { status: 400 });

  const sectionId = plan === "SECTION" ? String(b?.sectionId ?? "") : null;
  if (plan === "SECTION" && !sectionId) return Response.json({ error: "Choose a section" }, { status: 400 });

  const cfg = PLANS[plan];
  const endsAt = new Date(Date.now() + cfg.days * 86400000);

  // Launch mode: grant access immediately. Replace with a payment callback later.
  const sub = await prisma.subscription.create({
    data: { userId: acc.id, plan, status: "ACTIVE", print: Boolean(cfg.print), sectionId, endsAt },
    select: { id: true, plan: true, endsAt: true },
  });
  return Response.json(sub, { status: 201 });
}
IJRI_EOF

# ---------------------------------------------------------------- subscribe page (server gate) + options
cat > src/app/subscribe/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { T, Eyebrow } from "@/lib/ui";
import { IconLock } from "@/lib/icons";
import SubscribeOptions from "./SubscribeOptions";

export const dynamic = "force-dynamic";

export default async function Subscribe() {
  const acc = await getAccount();
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, select: { id: true, name: true } });
  const active = acc ? await prisma.subscription.findFirst({ where: { userId: acc.id, status: "ACTIVE", endsAt: { gte: new Date() } }, select: { plan: true, endsAt: true } }) : null;

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconLock size={22} /><Eyebrow inverse>Subscribe</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(28px,4.6vw,42px)", margin: "14px 0 8px" }}>Subscribe to IJRI</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17.5, lineHeight: 1.55, color: "#333", margin: "0 0 8px" }}>
        Abstracts are always free. A subscription unlocks full texts and PDF downloads across the journal.
      </p>
      <p style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, margin: "0 0 22px" }}>
        Launch pricing. Payment processing is being finalised — access is granted immediately on activation for now.
      </p>

      {!acc ? (
        <div style={{ border: `1px solid ${T.ink}`, padding: "20px", background: T.g50 }}>
          <p style={{ fontFamily: T.serif, fontSize: 17, margin: 0 }}>Please <Link href="/login" style={{ textDecoration: "underline" }}>sign in</Link> or <Link href="/register" style={{ textDecoration: "underline" }}>create an account</Link> to subscribe.</p>
        </div>
      ) : active ? (
        <div style={{ border: `2px solid ${T.ink}`, padding: "20px", background: T.g50 }}>
          <Eyebrow inverse>Active subscription</Eyebrow>
          <p style={{ fontFamily: T.serif, fontSize: 17, margin: "10px 0 0" }}>You have an active <strong>{active.plan.replace("_", " ").toLowerCase()}</strong> subscription valid until {new Date(active.endsAt).toLocaleDateString()}. Full texts are unlocked.</p>
          <Link href="/" style={{ display: "inline-block", marginTop: 14, fontFamily: T.sans, fontSize: 13, textDecoration: "underline", textTransform: "uppercase", letterSpacing: "0.06em" }}>Start reading →</Link>
        </div>
      ) : (
        <SubscribeOptions sections={sections} />
      )}
    </main>
  );
}
IJRI_EOF

cat > src/app/subscribe/SubscribeOptions.tsx << 'IJRI_EOF'
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
IJRI_EOF

echo ""
echo "Subscribe flow written. Now run:  npm run build"
