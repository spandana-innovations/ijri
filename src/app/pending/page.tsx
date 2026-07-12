import Link from "next/link";
import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import { T, Eyebrow } from "@/lib/ui";
import { IconShield } from "@/lib/icons";

export const dynamic = "force-dynamic";

export default async function Pending() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const ready = acc.approved || isStaff(acc.role);

  return (
    <main style={{ maxWidth: 620, margin: "60px auto", padding: "0 20px", textAlign: "center" }}>
      <div style={{ display: "inline-flex", color: T.ink }}><IconShield size={40} stroke={1.2} /></div>
      <div style={{ marginTop: 14 }}><Eyebrow inverse>{ready ? "Account active" : "Awaiting approval"}</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "14px 0 10px" }}>
        {ready ? `Welcome, ${acc.name}` : "Thanks for registering"}
      </h1>
      {ready ? (
        <>
          <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>
            Your account is active. You can now submit manuscripts and access member features.
          </p>
          <div style={{ marginTop: 20, display: "flex", gap: 12, justifyContent: "center" }}>
            <Link href="/submit" style={{ padding: "11px 18px", background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase" }}>Submit a manuscript</Link>
            {isStaff(acc.role) && <Link href="/admin" style={{ padding: "11px 18px", border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase" }}>Admin</Link>}
          </div>
        </>
      ) : (
        <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#333" }}>
          Your account has been created and is <strong>awaiting approval</strong> by the editorial office. Contributor access — including manuscript submission — is enabled once an administrator approves your account. You&rsquo;ll be able to submit as soon as that&rsquo;s done.
        </p>
      )}
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 26 }}>
        <Link href="/" style={{ textDecoration: "underline" }}>Return to the journal</Link>
      </p>
    </main>
  );
}
