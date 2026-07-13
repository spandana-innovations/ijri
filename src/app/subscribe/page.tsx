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
