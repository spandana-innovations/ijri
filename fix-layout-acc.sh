#!/usr/bin/env bash
# ==========================================================================
# IJRI — fix: layout.tsx uses `acc` in <BackendFab> but never declares it.
# The staff-bar injection added the component + imports but its anchor for the
# `const acc = await getAccount();` line didn't match. Add it after auth().
# Run in repo:  bash fix-layout-acc.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
P="src/app/layout.tsx"
[ -f "$P" ] || { echo "ERROR: $P not found"; exit 1; }

node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8"); let n = 0;

// 1) ensure getAccount is imported
if (!/from ["']@\/lib\/account["']/.test(s)) {
  if (s.includes(`import { Providers } from "./providers";`)) {
    s = s.replace(`import { Providers } from "./providers";`, `import { Providers } from "./providers";\nimport { getAccount } from "@/lib/account";`);
  } else {
    s = `import { getAccount } from "@/lib/account";\n` + s;
  }
  n++;
  console.log("  added getAccount import");
}

// 2) ensure `const acc = await getAccount();` exists
if (!/const\s+acc\s*=\s*await\s+getAccount\(\)/.test(s)) {
  if (/const\s+session\s*=\s*await\s+auth\(\);/.test(s)) {
    s = s.replace(/const\s+session\s*=\s*await\s+auth\(\);/, (m) => `${m}\n  const acc = await getAccount();`);
    n++; console.log("  declared acc after auth()");
  } else {
    // fallback: declare it just before the first use
    s = s.replace(/(\n\s*)<BackendFab /, `$1{/* acc */}$&`);
    console.log("  WARN: could not find auth() line — declare `const acc = await getAccount();` manually in the layout function");
  }
}

fs.writeFileSync(p, s);
console.log(`  ${n} change(s) applied`);
NODE

echo ""
echo "Fixed. Now run:  npm run build"
