#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#1) redesign Publication Ethics with visual UI, and (#9) add an
# APA 7th edition reference link on For Authors.
# Run in repo:  bash build-ethics-apa.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Ethics redesign + APA link..."
mkdir -p src/app/ethics src/app/for-authors

# ---------------------------------------------------------------- Ethics (visual)
cat > src/app/ethics/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconShield, IconScale, IconUsers, IconDoc, IconInfo } from "@/lib/icons";

const PRINCIPLES = [
  { icon: <IconDoc size={20} />, h: "Authors", d: "Work must be original and properly cited, not published or under consideration elsewhere. All listed authors must have genuinely contributed, and any conflicts of interest must be declared." },
  { icon: <IconScale size={20} />, h: "Plagiarism", d: "Submissions are screened for similarity in line with UGC guidelines. Plagiarised or fabricated content is rejected; published violations are corrected or retracted." },
  { icon: <IconUsers size={20} />, h: "Editors & reviewers", d: "Editors evaluate manuscripts solely on scholarly merit and maintain confidentiality. Reviewers disclose competing interests and decline where a conflict exists." },
  { icon: <IconInfo size={20} />, h: "Corrections & retractions", d: "The journal publishes corrections, expressions of concern, or retractions where warranted — transparently and promptly." },
];

export default function Ethics() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconShield size={26} /></div>
        <div><Eyebrow inverse>Publication Ethics</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>Ethics &amp; Malpractice Statement</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 640, margin: "0 auto" }}>
          IJRI upholds the highest standards of publication ethics, following the principles of the Committee on Publication Ethics (COPE).
        </p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, margin: "34px 0" }}>
        {PRINCIPLES.map((p) => (
          <div key={p.h} style={{ border: `1px solid ${T.rule}`, borderTop: `3px solid ${T.ink}`, padding: "20px 20px", background: T.paper }}>
            <div style={{ color: T.ink }}>{p.icon}</div>
            <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: "10px 0 6px" }}>{p.h}</h3>
            <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.6, color: T.muted, margin: 0 }}>{p.d}</p>
          </div>
        ))}
      </div>

      <div style={{ border: `2px solid ${T.ink}`, padding: "20px 22px", display: "flex", gap: 14, alignItems: "center", background: T.g50 }}>
        <IconShield size={22} />
        <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.55, margin: 0 }}>
          Concerns about research or publication integrity may be raised in confidence with the editorial office at <a href="mailto:editor@ijrein.org" style={{ textDecoration: "underline" }}>editor@ijrein.org</a>. Every report is reviewed under COPE guidance.
        </p>
      </div>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- APA link on For Authors (surgical)
if [ -f src/app/for-authors/page.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/app/for-authors/page.tsx";
let s = fs.readFileSync(p, "utf8");
const anchor = `<p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: 0 }}>Manuscripts are screened for similarity per UGC guidelines before review.</p>`;
const withLink = `<p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: 0 }}>Manuscripts are screened for similarity per UGC guidelines before review. References follow <a href="https://apastyle.apa.org/" target="_blank" rel="noopener noreferrer" style={{ textDecoration: "underline", color: T.ink }}>APA 7th edition style \u2197</a>.</p>`;
if (s.includes(anchor)) { fs.writeFileSync(p, s.replace(anchor, withLink)); console.log("  for-authors: APA 7 link added"); }
else if (s.includes("apastyle.apa.org")) { console.log("  for-authors: APA link already present"); }
else { console.log("  WARN: for-authors CTA text not found; add an APA link manually"); }
NODE
else
  echo "  WARN: for-authors page not found"
fi

echo ""
echo "Done. Now run:  npm run build"
