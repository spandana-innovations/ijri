"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T } from "@/lib/ui";

export default function SearchBox({ initial }: { initial: string }) {
  const [q, setQ] = useState(initial);
  const router = useRouter();
  return (
    <form onSubmit={(e) => { e.preventDefault(); router.push(`/search?q=${encodeURIComponent(q.trim())}`); }} style={{ display: "flex", gap: 10 }}>
      <input value={q} onChange={(e) => setQ(e.target.value)} autoFocus placeholder="Search articles, authors, keywords…"
        style={{ flex: 1, fontFamily: T.sans, fontSize: 15, padding: "12px 14px", border: `1px solid ${T.ink}`, background: T.paper }} />
      <button type="submit" style={{ padding: "12px 22px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 13, letterSpacing: "0.06em", textTransform: "uppercase", cursor: "pointer" }}>Search</button>
    </form>
  );
}
