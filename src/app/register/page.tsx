"use client";
import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { T } from "@/lib/ui";

export default function Register() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [affiliation, setAffiliation] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const res = await fetch("/api/auth/register", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, affiliation, password }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      setLoading(false); setErr(data.error ?? "Could not create account."); return;
    }
    await signIn("credentials", { email, password, redirect: false });
    setLoading(false);
    router.push("/"); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "11px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };
  const lbl: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted };

  return (
    <main style={{ maxWidth: 380, margin: "60px auto", padding: "0 20px" }}>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "0 0 6px" }}>Create account</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 22px" }}>Register as an author to submit manuscripts.</p>
      <form onSubmit={submit}>
        <label style={lbl}>Full name<input style={input} value={name} onChange={(e) => setName(e.target.value)} required /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Email<input style={input} type="email" value={email} onChange={(e) => setEmail(e.target.value)} required /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Affiliation (optional)<input style={input} value={affiliation} onChange={(e) => setAffiliation(e.target.value)} /></label>
        <div style={{ height: 14 }} />
        <label style={lbl}>Password<input style={input} type="password" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={8} /></label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ width: "100%", marginTop: 20, padding: "12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Creating…" : "Create account"}
        </button>
      </form>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 20 }}>
        Already have an account? <Link href="/login" style={{ textDecoration: "underline", color: T.ink }}>Sign in</Link>
      </p>
    </main>
  );
}
