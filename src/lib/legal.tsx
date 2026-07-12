import React from "react";
import { T, Eyebrow } from "@/lib/ui";

export function LegalPage({ eyebrow, title, icon, children }: { eyebrow: string; title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}>{icon}<Eyebrow inverse>{eyebrow}</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 20px" }}>{title}</h1>
      <div style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.62, color: "#1c1c1c" }}>{children}</div>
    </main>
  );
}

export function H({ children }: { children: React.ReactNode }) {
  return <h2 style={{ fontFamily: T.serif, fontSize: 22, margin: "28px 0 8px" }}>{children}</h2>;
}
