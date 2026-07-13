"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { T } from "@/lib/ui";

const STAFF = ["EDITOR", "CHIEF_EDITOR", "ADMIN"];

// Staff shortcuts on public article pages only. The Dashboard button lives
// in the top bar next to sign in / sign out.
export default function BackendFab({ loggedIn, role }: { loggedIn: boolean; role: string }) {
  const path = usePathname();
  if (!loggedIn || !STAFF.includes(role)) return null;
  const m = path.match(/^\/articles\/([^/]+)$/);
  if (!m) return null;
  const articleId = m[1];

  const base: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 15px", border: `1px solid ${T.ink}`, boxShadow: "0 2px 12px rgba(0,0,0,0.22)", cursor: "pointer" };

  return (
    <div style={{ position: "fixed", right: 16, bottom: 16, zIndex: 60, display: "flex", gap: 8 }}>
      <Link href={`/editor/${articleId}`} style={{ ...base, background: T.ink, color: T.paper }}>Review &amp; edit</Link>
      <Link href={`/history/${articleId}`} style={{ ...base, background: T.paper, color: T.ink }}>Edit log</Link>
    </div>
  );
}
