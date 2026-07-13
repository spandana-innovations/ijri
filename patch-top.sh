#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#2) larger footer logo, (#4) prominent Dashboard button in the top
# utility bar (it already sits beside the name; this makes it stand out).
# Surgical, non-fatal patches to layout.tsx.
# Run in repo:  bash patch-top.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
[ -f src/app/layout.tsx ] || { echo "ERROR: run from repo root (src/app/layout.tsx not found)"; exit 1; }

node - << 'NODE'
const fs = require("fs"); const p = "src/app/layout.tsx";
let s = fs.readFileSync(p, "utf8");
let changed = 0;

// (#2) footer logo 48 -> 64
const logoFrom = `<img src="/logo-wide-white.png" alt="IJRI" style={{ height: 48, width: "auto" }} />`;
const logoTo   = `<img src="/logo-wide-white.png" alt="IJRI" style={{ height: 64, width: "auto" }} />`;
if (s.includes(logoFrom)) { s = s.replace(logoFrom, logoTo); changed++; console.log("  footer logo -> 64px"); }
else if (s.includes(logoTo)) { console.log("  footer logo already 64px"); }
else console.log("  WARN: footer logo line not found");

// (#4) prominent Dashboard button
const btnFrom = `.dashbtn { border:1px solid ${'${T.ink}'}; padding:2px 9px; text-transform:uppercase; letter-spacing:.06em; }
          .dashbtn:hover { background:${'${T.ink}'}; color:${'${T.paper}'}; }`;
const btnTo = `.dashbtn { background:${'${T.ink}'}; color:${'${T.paper}'}; border:1px solid ${'${T.ink}'}; padding:3px 12px; text-transform:uppercase; letter-spacing:.06em; font-weight:600; }
          .dashbtn:hover { background:${'${T.paper}'}; color:${'${T.ink}'}; }`;
if (s.includes(btnFrom)) { s = s.replace(btnFrom, btnTo); changed++; console.log("  dashboard button -> filled/prominent"); }
else if (s.includes("background:${T.ink}; color:${T.paper}; border:1px solid ${T.ink}; padding:3px 12px")) { console.log("  dashboard button already prominent"); }
else console.log("  WARN: .dashbtn rule not found (adjust styling manually)");

if (changed) fs.writeFileSync(p, s);
console.log(`  ${changed} change(s) written`);
NODE

echo ""
echo "Done. Now run:  npm run build"
