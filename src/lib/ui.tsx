import React from "react";

export const T = {
  serif: "'Iowan Old Style','Charter','Palatino Linotype',Georgia,'Times New Roman',serif",
  sans: "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif",
  ink: "#111111", paper: "#ffffff", muted: "#6b6b6b", faint: "#f6f6f6", rule: "#e4e4e4",
};

export function Eyebrow({ children, inverse }: { children: React.ReactNode; inverse?: boolean }) {
  return (
    <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.14em", textTransform: "uppercase", fontWeight: 600, color: inverse ? T.paper : T.ink, background: inverse ? T.ink : "transparent", padding: inverse ? "3px 7px" : 0 }}>
      {children}
    </span>
  );
}

export function Chip({ children }: { children: React.ReactNode }) {
  return <span style={{ fontFamily: T.sans, fontSize: 11, color: T.ink, border: `1px solid ${T.rule}`, padding: "3px 8px", whiteSpace: "nowrap" }}>{children}</span>;
}

export function pages(a: { startPage?: number | null; endPage?: number | null }) {
  return a.startPage && a.endPage ? `${a.startPage}-${a.endPage}` : "";
}
