#!/usr/bin/env bash
# ==========================================================================
# IJRI — fix: the edit-history link injected into my-submissions used <Link>,
# which that page doesn't import. Switch it to a plain <a> (no import needed).
# Run in repo:  bash fix-history-link.sh  ->  npm run build
# ==========================================================================
set -euo pipefail

MS=""
for c in "src/app/(backend)/my-submissions/page.tsx" "src/app/my-submissions/page.tsx"; do
  [ -f "$c" ] && MS="$c" && break
done
[ -n "$MS" ] || { echo "ERROR: my-submissions page not found"; exit 1; }

MS="$MS" node - << 'NODE'
const fs = require("fs"); const p = process.env.MS;
let s = fs.readFileSync(p, "utf8"); let n = 0;

const from = `<Link href={\`/history/\${a.id}\`} style={{ fontFamily: T.sans, fontSize: 12, textDecoration: "underline", color: T.muted }}>Edit history →</Link>`;
const to   = `<a href={\`/history/\${a.id}\`} style={{ fontFamily: T.sans, fontSize: 12, textDecoration: "underline", color: T.muted }}>Edit history →</a>`;
if (s.includes(from)) { s = s.replace(from, to); n++; }

// safety net: if any other stray <Link ...>Edit history →</Link> exists, convert it too
s = s.replace(/<Link (href=\{`\/history\/\$\{a\.id\}`\}[^>]*)>Edit history →<\/Link>/g, (m, attrs) => { n++; return `<a ${attrs}>Edit history →</a>`; });

if (n) { fs.writeFileSync(p, s); console.log(`  converted ${n} history link(s) to <a> in ${p}`); }
else if (s.includes(`<a href={\`/history/\${a.id}\`}`)) console.log("  already using <a>");
else console.log("  WARN: history link not found — check manually");
NODE

echo ""
echo "Done. Now run:  npm run build"
