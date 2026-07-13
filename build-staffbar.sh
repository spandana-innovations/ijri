#!/usr/bin/env bash
# ==========================================================================
# IJRI — floating backend toolbar (solves "can't reach admin / can't act on a
# paper from the public site").
#   - Dashboard button, always visible when logged in            (#2)
#   - On any /articles/[id], staff also get Review&edit + Edit log (#1)
# Injected once into the root layout; the article page is NOT touched.
# Uses getAccount() for a RELIABLE role (the session JWT doesn't carry it).
# Run in repo:  bash build-staffbar.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Floating backend toolbar..."
mkdir -p src/components

cat > src/components/BackendFab.tsx << 'IJRI_EOF'
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
IJRI_EOF

# ---------------------------------------------------------------- inject into root layout
if [ -f src/app/layout.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8"); let n = 0;

if (!s.includes(`@/components/BackendFab`)) {
  s = s.replace(`import { Providers } from "./providers";`,
    `import { Providers } from "./providers";\nimport { getAccount } from "@/lib/account";\nimport BackendFab from "@/components/BackendFab";`);
  n++;
}
if (!s.includes(`const acc = await getAccount();`)) {
  s = s.replace(`const user = session?.user as { name?: string | null; role?: string } | undefined;`,
    `const user = session?.user as { name?: string | null; role?: string } | undefined;\n  const acc = await getAccount();`);
  n++;
}
if (!s.includes(`<BackendFab`)) {
  s = s.replace(`          {children}`, `          {children}\n          <BackendFab loggedIn={!!acc} role={acc?.role ?? ""} />`);
  n++;
}
fs.writeFileSync(p, s);
console.log(`  layout: ${n} injection(s) applied`);
NODE
else
  echo "  WARN: layout.tsx not found"
fi

echo ""
echo "Done. Now run:  npm run build"
