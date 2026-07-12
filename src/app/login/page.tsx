"use client";
import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { T } from "@/lib/ui";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true); setErr("");
    const res = await signIn("credentials", { email, password, redirect: false });
    setLoading(false);
    if (res?.error) setErr("Invalid email or password.");
    else { router.push("/"); router.refresh(); }
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 15, padding: "11px 12px", border: `1px solid ${T.ink}`, marginTop: 6, background: T.paper };

  return (
    <main style={{ maxWidth: 380, margin: "60px auto", padding: "0 20px" }}>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 30, margin: "0 0 6px" }}>Sign in</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 22px" }}>Access full articles, submissions, and the editorial desk.</p>
      <form onSubmit={submit}>
        <label style={{ fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted }}>Email
          <input style={input} type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        </label>
        <div style={{ height: 16 }} />
        <label style={{ fontFamily: T.sans, fontSize: 12, textTransform: "uppercase", letterSpacing: "0.06em", color: T.muted }}>Password
          <input style={input} type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        </label>
        {err && <p style={{ fontFamily: T.sans, fontSize: 13, color: "#b00020", margin: "14px 0 0" }}>{err}</p>}
        <button type="submit" disabled={loading} style={{ width: "100%", marginTop: 20, padding: "12px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", cursor: "pointer", opacity: loading ? 0.6 : 1 }}>
          {loading ? "Signing in…" : "Sign in"}
        </button>
      </form>
      <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 20 }}>
        No account? <Link href="/register" style={{ textDecoration: "underline", color: T.ink }}>Register</Link>
      </p>
    </main>
  );
}
