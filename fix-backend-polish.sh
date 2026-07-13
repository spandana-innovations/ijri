#!/usr/bin/env bash
# ==========================================================================
# IJRI — backend polish fixes:
#   (a) "Welcome, Dr" -> "Welcome, Cynthia" (strip title prefixes)
#   (b) top-bar Dashboard button now shows for ANY logged-in user
#       (it was gated on session.user.role, which the JWT doesn't carry)
# Run in repo:  bash fix-backend-polish.sh  ->  npm run build
# ==========================================================================
set -euo pipefail

# ---- (a) greeting: find the dashboard page wherever it lives --------------
DASH=""
for c in "src/app/(backend)/dashboard/page.tsx" "src/app/dashboard/page.tsx"; do
  [ -f "$c" ] && DASH="$c" && break
done
if [ -n "$DASH" ]; then
  DASH="$DASH" node - << 'NODE'
const fs = require("fs"); const p = process.env.DASH;
let s = fs.readFileSync(p, "utf8");
const from = `acc.name.split(/\\s+/)[0]`;
const to = `acc.name.replace(/^(Dr|Prof|Mr|Mrs|Ms)\\.?\\s+/i, "").split(/\\s+/)[0]`;
if (s.includes(from)) { fs.writeFileSync(p, s.split(from).join(to)); console.log("  greeting: strips title ->", p); }
else if (s.includes(`replace(/^(Dr|Prof`)) { console.log("  greeting already fixed"); }
else console.log("  WARN: greeting expression not found in", p);
NODE
else
  echo "  WARN: dashboard page not found"
fi

# ---- (b) top-bar Dashboard button: always show when logged in ------------
if [ -f src/app/layout.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8"); let n = 0;

// replace the role-gated button with an unconditional Dashboard link
const btnFrom = `{d && <Link href={d[0]} className="dashbtn">{d[1]}</Link>}`;
const btnTo = `<Link href="/dashboard" className="dashbtn">Dashboard</Link>`;
if (s.includes(btnFrom)) { s = s.replace(btnFrom, btnTo); n++; console.log("  button: always shown"); }
else if (s.includes(btnTo)) console.log("  button already unconditional");
else console.log("  WARN: dashboard button JSX not found");

// drop the now-unused `const d = dash(...)` line (avoids lint failure)
s = s.replace(/\n\s*const d = dash\(user\?\.role\);/, "");

// drop the now-unused dash() helper (2-line or role-based variants)
s = s.replace(/\nfunction dash\(role\?: string\)[\s\S]*?\n}\n/, "\n");

if (n) fs.writeFileSync(p, s);
console.log(`  layout updated (${n} core change)`);
NODE
else
  echo "  WARN: layout.tsx not found"
fi

echo ""
echo "Done. Now run:  npm run build"
