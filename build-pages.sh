#!/usr/bin/env bash
# ==========================================================================
# IJRI — visual redesign of the CONTENT pages (not compliance pages):
#   /for-authors   hero + at-a-glance + connected numbered process + CTA
#   /about         hero + feature grid + pull-quote + publisher strip
#   /aims-scope    hero + subject-area grid + article-type cards
# Stays within the monochrome broadsheet aesthetic, but with real structure.
# Run in repo:  bash build-pages.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Visual content pages..."
mkdir -p src/app/for-authors src/app/about src/app/aims-scope

# ---------------------------------------------------------------- For Authors
cat > src/app/for-authors/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { T, Eyebrow } from "@/lib/ui";
import { IconFeather, IconShield, IconScale, IconDoc, IconUsers, IconArrow } from "@/lib/icons";

const GLANCE = [
  { icon: <IconShield size={18} />, h: "Double-blind", d: "Every manuscript is peer-reviewed anonymously." },
  { icon: <IconScale size={18} />, h: "APA 7", d: "References follow APA 7th edition style." },
  { icon: <IconDoc size={18} />, h: "Original work", d: "Unpublished and not under review elsewhere." },
  { icon: <IconUsers size={18} />, h: "Declarations", d: "Authorship and conflicts stated up front." },
];

const STEPS = [
  { t: "Title", d: "A precise, appealing title that conveys the subject so researchers can find and cite your work." },
  { t: "Abstract", d: "State the purpose, the methodology, the findings, and the conclusions — plus any trial registry name, number, or URL where applicable." },
  { t: "Keywords", d: "Keywords mirror the topic and are mandatory for identifying the core concepts of the study." },
  { t: "Acknowledgements", d: "Credit is acknowledged where due. Referencing throughout follows the APA 7 style." },
  { t: "Author contributions", d: "State each author’s contribution to the article, whether single- or multi-authored." },
  { t: "Statements & declarations", d: "A ‘No conflict of interest’ declaration must be signed by the sole author or by each author." },
];

export default function ForAuthors() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      {/* hero */}
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconFeather size={26} /></div>
        <div><Eyebrow inverse>For Authors</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>Guidelines for Authors</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 620, margin: "0 auto" }}>
          Prepare your manuscript against the essentials below. Every submission undergoes double-blind peer review.
        </p>
      </div>

      {/* at a glance */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 0, border: `1px solid ${T.rule}`, borderTop: "none", marginBottom: 44 }}>
        {GLANCE.map((g, i) => (
          <div key={g.h} style={{ padding: "18px 16px", borderLeft: i === 0 ? "none" : `1px solid ${T.rule}` }}>
            <div style={{ color: T.ink }}>{g.icon}</div>
            <div style={{ fontFamily: T.sans, fontSize: 13, fontWeight: 600, letterSpacing: "0.02em", color: T.ink, margin: "8px 0 3px" }}>{g.h}</div>
            <div style={{ fontFamily: T.sans, fontSize: 12, lineHeight: 1.45, color: T.muted }}>{g.d}</div>
          </div>
        ))}
      </div>

      {/* process timeline with connector */}
      <Eyebrow>What to include</Eyebrow>
      <div style={{ position: "relative", marginTop: 18 }}>
        <div style={{ position: "absolute", left: 23, top: 24, bottom: 24, width: 1, background: T.g300 }} />
        {STEPS.map((s, i) => (
          <div key={s.t} style={{ position: "relative", display: "grid", gridTemplateColumns: "48px 1fr", gap: 18, padding: "16px 0", alignItems: "start" }}>
            <div style={{ position: "relative", zIndex: 1, width: 48, height: 48, borderRadius: "50%", border: `1.5px solid ${T.ink}`, background: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 20, fontWeight: 600 }}>{i + 1}</div>
            <div style={{ paddingTop: 4 }}>
              <h3 style={{ fontFamily: T.serif, fontSize: 21, margin: "0 0 4px" }}>{s.t}</h3>
              <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.6, color: "#2a2a2a", margin: 0 }}>{s.d}</p>
            </div>
          </div>
        ))}
      </div>

      {/* CTA */}
      <div style={{ marginTop: 34, border: `2px solid ${T.ink}`, padding: "26px 26px", display: "flex", flexWrap: "wrap", gap: 16, alignItems: "center", justifyContent: "space-between", background: T.g50 }}>
        <div>
          <h3 style={{ fontFamily: T.serif, fontSize: 24, margin: "0 0 4px" }}>Ready to submit?</h3>
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: 0 }}>Manuscripts are screened for similarity per UGC guidelines before review.</p>
        </div>
        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <Link href="/submit" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "13px 22px", background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase" }}>Submit <IconArrow size={15} /></Link>
          <Link href="/submit/word" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "13px 22px", background: T.paper, color: T.ink, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase" }}>Upload Word</Link>
        </div>
      </div>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- About
cat > src/app/about/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconBook, IconUsers, IconLock, IconLayers, IconShield } from "@/lib/icons";

const FEATURES = [
  { icon: <IconUsers size={20} />, h: "Double-blind peer review", d: "Every submission is evaluated anonymously by the editorial board; accepted articles are published by the Editor-in-Chief, with reviewing editors recorded on each article." },
  { icon: <IconLayers size={20} />, h: "Genuinely multidisciplinary", d: "Research across the sciences, engineering, management, and the social sciences sits side by side in a single scholarly record." },
  { icon: <IconLock size={20} />, h: "Open abstracts, subscriber full text", d: "Abstracts and metadata are free to everyone; full texts are available to subscribers and authorised members." },
  { icon: <IconShield size={20} />, h: "A permanent record", d: "Articles are archived by volume and issue with stable bibliographic details for citation." },
];

export default function About() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconBook size={26} /></div>
        <div><Eyebrow inverse>About</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>About the Journal</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 640, margin: "0 auto" }}>
          The International Journal of Research and Innovation is a multidisciplinary, double-blind peer-reviewed research journal.
        </p>
      </div>

      <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.68, color: "#1a1a1a", margin: "30px 0" }}>
        IJRI publishes original research, reviews, and scholarly commentary across the sciences, engineering, management, and the social sciences — advancing rigorous work and making it accessible to researchers, practitioners, and policymakers.
      </p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        {FEATURES.map((f) => (
          <div key={f.h} style={{ border: `1px solid ${T.rule}`, padding: "20px 20px", background: T.paper }}>
            <div style={{ color: T.ink }}>{f.icon}</div>
            <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: "10px 0 6px" }}>{f.h}</h3>
            <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.6, color: T.muted, margin: 0 }}>{f.d}</p>
          </div>
        ))}
      </div>

      <blockquote style={{ margin: "40px 0", padding: "6px 0 6px 22px", borderLeft: `3px solid ${T.ink}`, fontFamily: T.serif, fontStyle: "italic", fontSize: 22, lineHeight: 1.5, color: "#222" }}>
        Rigorous scholarship, openly indexed and permanently archived — so good research is easy to find, cite, and build upon.
      </blockquote>

      <div style={{ border: `1px solid ${T.ink}`, padding: "18px 20px", display: "flex", gap: 14, alignItems: "center", background: T.g50 }}>
        <IconShield size={20} />
        <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.55, color: T.ink, margin: 0 }}>
          <strong>Publisher.</strong> IJRI is published online at ijrein.org and maintains a permanent editorial office for all correspondence.
        </p>
      </div>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- Aims & Scope
cat > src/app/aims-scope/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconLayers, IconDoc, IconBook, IconScale, IconShield, IconUsers, IconFeather } from "@/lib/icons";

const SUBJECTS = [
  { icon: <IconDoc size={20} />, name: "Computer & Information Science" },
  { icon: <IconShield size={20} />, name: "Medicine & Public Health" },
  { icon: <IconLayers size={20} />, name: "Engineering" },
  { icon: <IconScale size={20} />, name: "Economics & Management" },
  { icon: <IconBook size={20} />, name: "Materials Science" },
  { icon: <IconUsers size={20} />, name: "Social Sciences" },
];

const TYPES = [
  { h: "Original research", d: "Full-length articles presenting new, methodologically sound findings." },
  { h: "Systematic reviews", d: "Structured syntheses that map and evaluate a body of evidence." },
  { h: "Scholarly commentary", d: "Considered perspectives on questions of significance to a field." },
];

export default function AimsScope() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconLayers size={26} /></div>
        <div><Eyebrow inverse>Aims & Scope</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>Aims &amp; Scope</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 640, margin: "0 auto" }}>
          IJRI advances rigorous, original scholarship and makes it accessible to researchers, practitioners, and policymakers.
        </p>
      </div>

      <Eyebrow>Subject areas</Eyebrow>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14, margin: "14px 0 40px" }}>
        {SUBJECTS.map((s) => (
          <div key={s.name} style={{ border: `1px solid ${T.rule}`, padding: "20px 16px", textAlign: "center", background: T.paper }}>
            <div style={{ display: "flex", justifyContent: "center", color: T.ink, marginBottom: 10 }}>{s.icon}</div>
            <div style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.3 }}>{s.name}</div>
          </div>
        ))}
      </div>

      <Eyebrow>Article types</Eyebrow>
      <div style={{ margin: "14px 0 34px" }}>
        {TYPES.map((t, i) => (
          <div key={t.h} style={{ display: "grid", gridTemplateColumns: "1fr", gap: 2, padding: "16px 0", borderTop: `1px solid ${T.rule}`, borderBottom: i === TYPES.length - 1 ? `1px solid ${T.rule}` : "none" }}>
            <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: 0 }}>{t.h}</h3>
            <p style={{ fontFamily: T.sans, fontSize: 14, lineHeight: 1.55, color: T.muted, margin: 0 }}>{t.d}</p>
          </div>
        ))}
      </div>

      <div style={{ border: `2px solid ${T.ink}`, padding: "20px 22px", display: "flex", gap: 14, alignItems: "center", background: T.g50 }}>
        <IconFeather size={22} />
        <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.55, margin: 0 }}>
          All submissions are prepared per the guidelines for authors and undergo double-blind peer review.
        </p>
      </div>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Content pages redesigned. Now run:  npm run build"
