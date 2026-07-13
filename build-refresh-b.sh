#!/usr/bin/env bash
# ==========================================================================
# IJRI — refresh B: layout (single rule, larger footer logo, role buttons,
# refunds link) + livelier For Authors / Ethics / About / Aims & Scope pages.
# Run in repo:  bash build-refresh-b.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Refresh B: layout + lively content pages..."
mkdir -p src/lib src/app/for-authors src/app/ethics src/app/about src/app/aims-scope

# ---------------------------------------------------------------- layout
cat > src/app/layout.tsx << 'IJRI_EOF'
import Link from "next/link";
import { T } from "@/lib/ui";
import { IconBook, IconFeather, IconShield, IconArrow } from "@/lib/icons";
import { auth, signOut } from "@/auth";
import { Providers } from "./providers";

export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary, double-blind peer-reviewed research journal.",
};

const CURRENT = "Volume 1, Issue 1 · July 2026";
const NAV: [string, string][] = [
  ["/", "Home"], ["/archives", "Archives"], ["/sections", "Sections"],
  ["/editorial-board", "Editorial Board"], ["/for-authors", "For Authors"],
];
const FOOTER_COLS: { head: string; icon: React.ReactNode; links: [string, string][] }[] = [
  { head: "The Journal", icon: <IconBook size={16} />, links: [["/about", "About"], ["/aims-scope", "Aims & Scope"], ["/editorial-board", "Editorial Board"], ["/archives", "Archives"], ["/sections", "Sections"]] },
  { head: "For Authors", icon: <IconFeather size={16} />, links: [["/for-authors", "Author Guidelines"], ["/login", "Submit a Manuscript"], ["/ethics", "Publication Ethics"], ["/copyright", "Copyright & Licensing"]] },
  { head: "Policies & Info", icon: <IconShield size={16} />, links: [["/privacy", "Privacy Policy"], ["/terms", "Terms & Conditions"], ["/refunds", "Refund Policy"], ["/contact", "Contact"]] },
];

// role -> dashboard link
function dash(role?: string): [string, string] | null {
  if (role === "ADMIN" || role === "CHIEF_EDITOR") return ["/admin", "Admin"];
  if (role === "EDITOR") return ["/editor", "Review desk"];
  if (role === "AUTHOR") return ["/submit", "Submit"];
  return null;
}

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const user = session?.user as { name?: string | null; role?: string } | undefined;
  const d = dash(user?.role);

  return (
    <html lang="en">
      <body style={{ margin: 0, background: T.paper, color: T.ink }}>
        <style>{`
          * { box-sizing: border-box; }
          a { color: inherit; text-decoration: none; }
          .nav a:hover { background:${T.g200}; }
          .cardtitle { text-decoration: underline transparent; text-underline-offset: 3px; transition: text-decoration-color .15s; }
          a:hover .cardtitle { text-decoration-color: ${T.ink}; }
          .body h2 { font-family:${T.serif}; font-size:22px; margin:28px 0 10px; }
          .body p { font-family:${T.serif}; font-size:18.5px; line-height:1.68; margin:0 0 20px; color:#1a1a1a; }
          .body blockquote { font-family:${T.serif}; font-style:italic; border-left:3px solid ${T.ink}; margin:24px 0; padding:4px 0 4px 18px; color:#333; }
          .body p:first-of-type::first-letter { font-family:${T.serif}; float:left; font-size:62px; line-height:.82; padding:6px 10px 0 0; font-weight:600; }
          .footlink { color:${T.footerText}; display:flex; align-items:center; gap:6px; padding:5px 0; font-size:13.5px; transition:color .15s; }
          .footlink:hover { color:#fff; }
          .footlink .fa { opacity:0; transform:translateX(-4px); transition:all .15s; }
          .footlink:hover .fa { opacity:1; transform:translateX(0); }
          .linkbtn { background:none; border:none; padding:0; cursor:pointer; font:inherit; color:inherit; }
          .dashbtn { border:1px solid ${T.ink}; padding:2px 9px; text-transform:uppercase; letter-spacing:.06em; }
          .dashbtn:hover { background:${T.ink}; color:${T.paper}; }
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} .footgrid{grid-template-columns:1fr 1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} .utilbar{font-size:10px !important;} .footgrid{grid-template-columns:1fr !important;} }
        `}</style>

        <Providers>
          <header style={{ borderBottom: `1px solid ${T.ink}`, background: T.paper }}>
            <div style={{ borderBottom: `1px solid ${T.rule}`, background: T.g50 }}>
              <div className="utilbar" style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
                <span>e-ISSN: applied for</span>
                {user ? (
                  <span style={{ display: "flex", gap: 12, alignItems: "center" }}>
                    {d && <Link href={d[0]} className="dashbtn">{d[1]}</Link>}
                    <span style={{ color: T.ink }}>{user.name}</span>
                    <form action={async () => { "use server"; await signOut({ redirectTo: "/" }); }}>
                      <button className="linkbtn" style={{ textTransform: "uppercase", letterSpacing: "0.06em", textDecoration: "underline", textUnderlineOffset: 2 }}>Sign out</button>
                    </form>
                  </span>
                ) : (
                  <Link href="/login" style={{ textDecoration: "underline", textUnderlineOffset: 2 }}>Sign in</Link>
                )}
              </div>
            </div>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "22px 20px 15px", textAlign: "center" }}>
              <Link href="/" style={{ display: "inline-block" }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/logo-stacked.png" alt="International Journal of Research and Innovation" style={{ height: "clamp(86px,15vw,130px)", width: "auto" }} />
              </Link>
            </div>
            <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
                Current issue · {CURRENT}
              </div>
            </div>
            <nav className="nav" style={{ background: T.g100 }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
                {NAV.map(([href, label]) => (
                  <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
                ))}
              </div>
            </nav>
          </header>

          {children}

          <footer style={{ background: T.footer, marginTop: 48 }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "48px 20px 22px" }}>
              <div className="footgrid" style={{ display: "grid", gridTemplateColumns: "1.6fr 1fr 1fr 1fr", gap: 36 }}>
                <div>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 48, width: "auto" }} />
                  <p style={{ fontFamily: T.serif, fontSize: 14.5, lineHeight: 1.6, color: T.footerText, margin: "18px 0 0", maxWidth: 320 }}>
                    A multidisciplinary, double-blind peer-reviewed research journal publishing across the sciences, engineering, management, and the social sciences.
                  </p>
                  <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.g400, marginTop: 18 }}>e-ISSN: applied for · ijrein.org</div>
                </div>
                {FOOTER_COLS.map((col) => (
                  <div key={col.head}>
                    <div style={{ display: "flex", alignItems: "center", gap: 7, color: "#fff", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.1em", textTransform: "uppercase", fontWeight: 600, paddingBottom: 12, marginBottom: 6, borderBottom: `1px solid #2c2c30` }}>
                      {col.icon}<span>{col.head}</span>
                    </div>
                    {col.links.map(([href, label]) => (
                      <Link key={href} href={href} className="footlink" style={{ fontFamily: T.sans }}>
                        <span>{label}</span><span className="fa"><IconArrow size={13} /></span>
                      </Link>
                    ))}
                  </div>
                ))}
              </div>
              <div style={{ borderTop: `1px solid #2c2c30`, marginTop: 34, paddingTop: 20, display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 10, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", color: T.g400 }}>
                <span>© 2026 International Journal of Research and Innovation</span>
                <span>All rights reserved</span>
              </div>
            </div>
          </footer>
        </Providers>
      </body>
    </html>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- richer legal helpers
cat > src/lib/legal.tsx << 'IJRI_EOF'
import React from "react";
import { T, Eyebrow } from "@/lib/ui";

export function LegalPage({ eyebrow, title, icon, intro, children }: { eyebrow: string; title: string; icon?: React.ReactNode; intro?: React.ReactNode; children: React.ReactNode }) {
  return (
    <main style={{ maxWidth: 780, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}>{icon}<Eyebrow inverse>{eyebrow}</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(28px,4.6vw,42px)", margin: "14px 0 12px" }}>{title}</h1>
      {intro && <p style={{ fontFamily: T.serif, fontSize: 18, lineHeight: 1.6, color: "#333", margin: "0 0 10px" }}>{intro}</p>}
      <div style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.62, color: "#1c1c1c" }}>{children}</div>
    </main>
  );
}

export function H({ children }: { children: React.ReactNode }) {
  return <h2 style={{ fontFamily: T.serif, fontSize: 22, margin: "28px 0 8px" }}>{children}</h2>;
}

export function Card({ icon, title, children }: { icon?: React.ReactNode; title: string; children: React.ReactNode }) {
  return (
    <div style={{ border: `1px solid ${T.rule}`, borderLeft: `3px solid ${T.ink}`, padding: "16px 20px", margin: "14px 0", background: T.g50 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 9, color: T.ink }}>
        {icon}<h3 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600, margin: 0 }}>{title}</h3>
      </div>
      <div style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.6, color: "#2a2a2a", marginTop: 8 }}>{children}</div>
    </div>
  );
}

export function Step({ n, title, children }: { n: number; title: string; children: React.ReactNode }) {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "44px 1fr", gap: 16, padding: "18px 0", borderTop: `1px solid ${T.rule}`, alignItems: "start" }}>
      <div style={{ width: 40, height: 40, border: `1.5px solid ${T.ink}`, borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 19, fontWeight: 600 }}>{n}</div>
      <div>
        <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: "0 0 5px" }}>{title}</h3>
        <div style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.6, color: "#2a2a2a" }}>{children}</div>
      </div>
    </div>
  );
}

export function Chips({ items }: { items: string[] }) {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 8, margin: "12px 0 6px" }}>
      {items.map((it) => (
        <span key={it} style={{ fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.02em", border: `1px solid ${T.ink}`, padding: "5px 11px", background: T.paper }}>{it}</span>
      ))}
    </div>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- For Authors (numbered, lively)
cat > src/app/for-authors/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { LegalPage, Step } from "@/lib/legal";
import { T } from "@/lib/ui";
import { IconFeather } from "@/lib/icons";

export default function ForAuthors() {
  return (
    <LegalPage eyebrow="For Authors" title="Guidelines for Authors" icon={<IconFeather size={22} />}
      intro="Prepare your manuscript against the following before submitting. All submissions undergo double-blind peer review.">
      <div style={{ margin: "18px 0" }}>
        <Step n={1} title="Title">A precise, appealing title that conveys the subject so researchers can find and cite your work.</Step>
        <Step n={2} title="Abstract">
          Include, specifically:
          <ul style={{ margin: "8px 0 0", paddingLeft: 20 }}>
            <li>The stated purpose of the study or research</li>
            <li>A brief account of the methodology undertaken</li>
            <li>The findings of the study</li>
            <li>The conclusions of the research</li>
            <li>Any trial registry name, registration number, or URL, if applicable</li>
          </ul>
        </Step>
        <Step n={3} title="Keywords">Keywords mirror the topic and are mandatory for identifying the core concepts of the study.</Step>
        <Step n={4} title="Acknowledgements">Credit is acknowledged where due. Referencing follows the APA 7 style.</Step>
        <Step n={5} title="Author contributions">State each author&rsquo;s contribution to the article, whether single- or multi-authored.</Step>
        <Step n={6} title="Statements & declarations">A &lsquo;No conflict of interest&rsquo; declaration must be signed by the sole author or by each author.</Step>
      </div>
      <div style={{ borderTop: `2px solid ${T.ink}`, paddingTop: 18, marginTop: 10 }}>
        <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: "0 0 12px" }}>Manuscripts are screened for similarity in line with UGC plagiarism guidelines before review.</p>
        <Link href="/submit" style={{ display: "inline-block", padding: "12px 22px", background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 13, letterSpacing: "0.08em", textTransform: "uppercase" }}>Submit a manuscript →</Link>
      </div>
    </LegalPage>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- Ethics (carded)
cat > src/app/ethics/page.tsx << 'IJRI_EOF'
import { LegalPage, Card } from "@/lib/legal";
import { IconShield, IconScale, IconUsers, IconDoc } from "@/lib/icons";

export default function Ethics() {
  return (
    <LegalPage eyebrow="Publication Ethics" title="Publication Ethics & Malpractice Statement" icon={<IconShield size={22} />}
      intro="IJRI upholds the highest standards of publication ethics, following the principles of the Committee on Publication Ethics (COPE).">
      <Card icon={<IconFeatherSafe />} title="Authors">
        Work must be original and properly cited, not published or under consideration elsewhere. All listed authors must have genuinely contributed, and conflicts of interest must be declared.
      </Card>
      <Card icon={<IconScale size={18} />} title="Plagiarism">
        Submissions are screened for similarity in line with UGC guidelines. Plagiarised or fabricated content is rejected; published violations are corrected or retracted.
      </Card>
      <Card icon={<IconUsers size={18} />} title="Editors & reviewers">
        Editors evaluate manuscripts solely on scholarly merit and maintain confidentiality. Reviewers disclose competing interests and decline where a conflict exists.
      </Card>
      <Card icon={<IconDoc size={18} />} title="Corrections & retractions">
        The journal publishes corrections, expressions of concern, or retractions where warranted, transparently and promptly.
      </Card>
    </LegalPage>
  );
}
function IconFeatherSafe() { return <span style={{ width: 18, height: 18, display: "inline-block" }} />; }
IJRI_EOF

# ---------------------------------------------------------------- About (icon sections)
cat > src/app/about/page.tsx << 'IJRI_EOF'
import { LegalPage, Card } from "@/lib/legal";
import { IconBook, IconShield, IconLock, IconUsers } from "@/lib/icons";

export default function About() {
  return (
    <LegalPage eyebrow="About" title="About the Journal" icon={<IconBook size={22} />}
      intro="The International Journal of Research and Innovation (IJRI) is a multidisciplinary, double-blind peer-reviewed research journal.">
      <p>IJRI publishes original research, reviews, and scholarly commentary across the sciences, engineering, management, and the social sciences, advancing rigorous work and making it accessible to researchers, practitioners, and policymakers.</p>
      <Card icon={<IconUsers size={18} />} title="Peer review">Every submission is evaluated under a double-blind process by the editorial board. Accepted articles are published by the Editor-in-Chief, with reviewing editors and bibliographic details recorded on each article.</Card>
      <Card icon={<IconLock size={18} />} title="Access">Abstracts and metadata are free to all readers. Full texts are available to subscribers and authorised members of the journal.</Card>
      <Card icon={<IconShield size={18} />} title="Publisher">IJRI is published online at ijrein.org and maintains a permanent editorial office for all correspondence.</Card>
    </LegalPage>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- Aims & Scope (chips + sections)
cat > src/app/aims-scope/page.tsx << 'IJRI_EOF'
import { LegalPage, Card, Chips } from "@/lib/legal";
import { IconLayers, IconDoc } from "@/lib/icons";

export default function AimsScope() {
  return (
    <LegalPage eyebrow="Aims & Scope" title="Aims & Scope" icon={<IconLayers size={22} />}
      intro="IJRI advances rigorous, original scholarship and makes it accessible to researchers, practitioners, and policymakers.">
      <p>As a multidisciplinary journal, IJRI welcomes methodologically sound work of clear significance to its field.</p>
      <Card icon={<IconLayers size={18} />} title="Subject areas">
        <Chips items={["Computer & Information Science", "Medicine & Public Health", "Engineering", "Economics & Management", "Materials Science", "Social Sciences"]} />
      </Card>
      <Card icon={<IconDoc size={18} />} title="Article types">
        Original research articles, systematic reviews, and scholarly commentary are considered. All submissions are prepared per the guidelines for authors and undergo double-blind peer review.
      </Card>
    </LegalPage>
  );
}
IJRI_EOF

echo ""
echo "Refresh B written. Now run:  npm run build"
echo "  git add . && git commit -m 'Refresh: EIC, board, lively pages, layout' && git push origin main"
