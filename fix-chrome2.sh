#!/usr/bin/env bash
# ==========================================================================
# IJRI — header & naming fixes.
#   (#8) "◆ Dashboard" moves to the TOP bar next to sign in / sign out,
#        shown for ANY logged-in user (the old one was role-gated on a JWT
#        field that is always empty — that's why it never appeared).
#        The floating toolbar keeps ONLY the staff shortcuts on articles
#        (Review & edit, Edit log) — its Dashboard button is removed.
#   (#7) "Usage analytics" -> "Application analytics" (menu, dashboard card,
#        page heading).
# Run in repo:  bash fix-chrome2.sh  ->  npm run build
# ==========================================================================
set -euo pipefail

# ---------------------------------------------------------------- (a) header: Dashboard next to sign in/out
[ -f src/app/layout.tsx ] || { echo "ERROR: src/app/layout.tsx not found"; exit 1; }
node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8"); let n = 0;

// 1) role-gated button -> unconditional (the JWT has no role, so the old one never rendered)
const btnFrom = `{d && <Link href={d[0]} className="dashbtn">{d[1]}</Link>}`;
const btnTo = `<Link href="/dashboard" className="dashbtn">◆ Dashboard</Link>`;
if (s.includes(btnFrom)) { s = s.replace(btnFrom, btnTo); n++; console.log("  header: Dashboard now unconditional"); }
else if (s.includes(`href="/dashboard"`)) { console.log("  header: Dashboard link already present"); }
else {
  // 2) fallback: insert before the user-name span in the logged-in branch
  const anchor = `<span style={{ color: T.ink }}>{user.name}</span>`;
  if (s.includes(anchor)) { s = s.replace(anchor, `${btnTo}\n                    ${anchor}`); n++; console.log("  header: Dashboard inserted next to sign out"); }
  else console.log("  WARN: could not find a header anchor — add the Dashboard link manually");
}

// 3) clean up the now-unused role helper (either variant), harmless if absent
s = s.replace(/\n\s*const d = dash\(user\?\.role\);/, "");
s = s.replace(/\nfunction dash\(role\?: string\)[\s\S]*?\n}\n/, "\n");

// 4) ensure the .dashbtn style exists (older layouts may lack it)
if (!s.includes(".dashbtn")) {
  s = s.replace("* { box-sizing: border-box; }", "* { box-sizing: border-box; }\n          .dashbtn { border:1px solid ${T.ink}; padding:2px 9px; text-transform:uppercase; letter-spacing:.06em; }\n          .dashbtn:hover { background:${T.ink}; color:${T.paper}; }");
  console.log("  header: .dashbtn style added");
}
fs.writeFileSync(p, s);
NODE

# ---------------------------------------------------------------- (b) floating toolbar: staff article shortcuts only
if [ -f src/components/BackendFab.tsx ]; then
cat > src/components/BackendFab.tsx << 'IJRI_EOF'
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
IJRI_EOF
echo "  floating toolbar: Dashboard removed; staff article shortcuts kept"
else
echo "  note: BackendFab.tsx not found (staff shortcuts skipped)"
fi

# ---------------------------------------------------------------- (c) rename: Usage analytics -> Application analytics
node - << 'NODE'
const fs = require("fs");
const targets = [
  "src/components/BackendNav.tsx",
  "src/app/(backend)/dashboard/page.tsx", "src/app/dashboard/page.tsx",
  "src/app/(backend)/admin/analytics/page.tsx", "src/app/admin/analytics/page.tsx",
];
let total = 0;
for (const p of targets) {
  if (!fs.existsSync(p)) continue;
  let s = fs.readFileSync(p, "utf8");
  const before = s;
  s = s.split("Usage analytics").join("Application analytics");
  s = s.split(">Readership analytics<").join(">Application analytics<");
  if (s !== before) { fs.writeFileSync(p, s); const k = (before.match(/Usage analytics|>Readership analytics</g) || []).length; total += k; console.log(`  renamed in ${p}`); }
}
console.log(`  ${total} label(s) renamed to "Application analytics"`);
NODE

echo ""
echo "Chrome fixes done. Now run:  npm run build"
