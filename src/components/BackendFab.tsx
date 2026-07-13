"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { T } from "@/lib/ui";

const STAFF = ["EDITOR", "CHIEF_EDITOR", "ADMIN"];

export default function BackendFab({ loggedIn, role }: { loggedIn: boolean; role: string }) {
  const path = usePathname();
  if (!loggedIn) return null;
  if (path.startsWith("/dashboard") || path.startsWith("/admin") || path.startsWith("/editor") || path.startsWith("/my-submissions") || path.startsWith("/submit")) return null;

  const m = path.match(/^\/articles\/([^/]+)$/);
  const articleId = m?.[1];
  const isStaff = STAFF.includes(role);

  const base: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 15px", border: `1px solid ${T.ink}`, boxShadow: "0 2px 12px rgba(0,0,0,0.22)", cursor: "pointer" };
  const dark: React.CSSProperties = { ...base, background: T.ink, color: T.paper };
  const light: React.CSSProperties = { ...base, background: T.paper, color: T.ink };

  return (
    <div style={{ position: "fixed", right: 16, bottom: 16, zIndex: 60, display: "flex", gap: 8, flexWrap: "wrap", justifyContent: "flex-end", maxWidth: "92vw" }}>
      {articleId && isStaff && (
        <>
          <Link href={`/editor/${articleId}`} style={dark}>Review &amp; edit</Link>
          <Link href={`/history/${articleId}`} style={light}>Edit log</Link>
        </>
      )}
      <Link href="/dashboard" style={dark}>◆ Dashboard</Link>
    </div>
  );
}
