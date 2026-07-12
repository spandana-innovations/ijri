#!/usr/bin/env bash
# ==========================================================================
# IJRI — stage 2b (UI): logo 135%, grays, icons, vivid footer, compliance
# pages, standardized editorial board (no contact details).
# No new dependencies, no schema/auth changes.
# Run in the repo:  bash build-stage2b-ui.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Stage 2b UI: footer, compliance pages, icons, board..."
mkdir -p src/lib src/app/editorial-board src/app/about src/app/aims-scope src/app/ethics \
         src/app/privacy src/app/terms src/app/copyright src/app/contact

# ---------------------------------------------------------------- gray tokens (append-safe rewrite)
cat > src/lib/ui.tsx << 'IJRI_EOF'
import React from "react";

export const T = {
  serif: "'Iowan Old Style','Charter','Palatino Linotype',Georgia,'Times New Roman',serif",
  sans: "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif",
  ink: "#111111",
  paper: "#ffffff",
  muted: "#6b6b6b",
  // gray scale
  g50: "#fafafa",
  g100: "#f4f4f5",
  g200: "#e9e9ec",
  g300: "#d6d6da",
  g400: "#9a9aa2",
  faint: "#f6f6f6",
  rule: "#e4e4e4",
  footer: "#141416",
  footerText: "#a1a1a8",
};

export function Eyebrow({ children, inverse }: { children: React.ReactNode; inverse?: boolean }) {
  return (
    <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.14em", textTransform: "uppercase", fontWeight: 600, color: inverse ? T.paper : T.ink, background: inverse ? T.ink : "transparent", padding: inverse ? "3px 7px" : 0 }}>
      {children}
    </span>
  );
}

export function Chip({ children }: { children: React.ReactNode }) {
  return <span style={{ fontFamily: T.sans, fontSize: 11, color: T.ink, border: `1px solid ${T.rule}`, padding: "3px 8px", whiteSpace: "nowrap" }}>{children}</span>;
}

export function pages(a: { startPage?: number | null; endPage?: number | null }) {
  return a.startPage && a.endPage ? `${a.startPage}-${a.endPage}` : "";
}
IJRI_EOF

# ---------------------------------------------------------------- inline SVG icons (Apple-style thin line)
cat > src/lib/icons.tsx << 'IJRI_EOF'
import React from "react";

type P = { size?: number; stroke?: number; style?: React.CSSProperties };
const base = (size: number, stroke: number): React.SVGProps<SVGSVGElement> => ({
  width: size, height: size, viewBox: "0 0 24 24", fill: "none",
  stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round",
});

export const IconBook = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M4 5a2 2 0 0 1 2-2h9v16H6a2 2 0 0 0-2 2z" /><path d="M15 3h3a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2h-3" /></svg>
);
export const IconDoc = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M6 2h8l4 4v16H6z" /><path d="M14 2v4h4" /><path d="M9 13h6M9 17h6" /></svg>
);
export const IconUsers = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><circle cx="9" cy="8" r="3" /><path d="M3 20a6 6 0 0 1 12 0" /><path d="M16 6a3 3 0 0 1 0 6M21 20a6 6 0 0 0-4-5.7" /></svg>
);
export const IconMail = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>
);
export const IconShield = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M12 3 5 6v5c0 4 3 7 7 9 4-2 7-5 7-9V6z" /><path d="m9 12 2 2 4-4" /></svg>
);
export const IconScale = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M12 3v18M7 21h10" /><path d="M12 5 5 8l-2 5a4 4 0 0 0 8 0L9 8M12 5l7 3 2 5a4 4 0 0 1-8 0l2-5" /></svg>
);
export const IconLayers = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="m12 3 9 5-9 5-9-5z" /><path d="m3 13 9 5 9-5" /></svg>
);
export const IconArchive = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="3" y="4" width="18" height="4" rx="1" /><path d="M5 8v11a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8" /><path d="M10 12h4" /></svg>
);
export const IconFeather = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M20 4a7 7 0 0 0-10 0L4 10v10h10l6-6a7 7 0 0 0 0-4" /><path d="M16 8 4 20M16 12H9" /></svg>
);
export const IconLock = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 0 1 8 0v3" /></svg>
);
export const IconArrow = ({ size = 18, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M5 12h14M13 6l6 6-6 6" /></svg>
);
export const IconInfo = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 8h.01" /></svg>
);
IJRI_EOF

# ---------------------------------------------------------------- layout: logo 135%, grays, vivid footer, icons
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
  ["/", "Home"],
  ["/archives", "Archives"],
  ["/sections", "Sections"],
  ["/editorial-board", "Editorial Board"],
  ["/for-authors", "For Authors"],
];

const FOOTER_COLS: { head: string; icon: React.ReactNode; links: [string, string][] }[] = [
  { head: "The Journal", icon: <IconBook size={16} />, links: [["/about", "About"], ["/aims-scope", "Aims & Scope"], ["/editorial-board", "Editorial Board"], ["/archives", "Archives"], ["/sections", "Sections"]] },
  { head: "For Authors", icon: <IconFeather size={16} />, links: [["/for-authors", "Author Guidelines"], ["/login", "Submit a Manuscript"], ["/ethics", "Publication Ethics"], ["/copyright", "Copyright & Licensing"]] },
  { head: "Policies & Info", icon: <IconShield size={16} />, links: [["/privacy", "Privacy Policy"], ["/terms", "Terms & Conditions"], ["/contact", "Contact"]] },
];

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const user = session?.user as { name?: string | null } | undefined;

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
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} .footgrid{grid-template-columns:1fr 1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} .utilbar{font-size:10px !important;} .footgrid{grid-template-columns:1fr !important;} }
        `}</style>

        <Providers>
          <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
            <div style={{ borderBottom: `1px solid ${T.rule}`, background: T.g50 }}>
              <div className="utilbar" style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
                <span>e-ISSN: applied for</span>
                {user ? (
                  <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
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
                  <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 34, width: "auto" }} />
                  <p style={{ fontFamily: T.serif, fontSize: 14.5, lineHeight: 1.6, color: T.footerText, margin: "16px 0 0", maxWidth: 320 }}>
                    A multidisciplinary, double-blind peer-reviewed research journal publishing across the sciences, engineering, management, and the social sciences.
                  </p>
                  <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.g400, marginTop: 18 }}>
                    e-ISSN: applied for · Published on ijrein.org
                  </div>
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
                <span>All rights reserved · Content is copyright of the respective authors and the journal</span>
              </div>
            </div>
          </footer>
        </Providers>
      </body>
    </html>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- standardized editorial board (no contacts)
cat > src/app/editorial-board/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type Member = { name: string; title: string; affiliation: string; bio?: string; photo?: string };

const TEAM: Member[] = [
  { name: "Prof. Vidyadhar Reddy Aileni", title: "Former Dean, Faculty of Management", affiliation: "Osmania University; former Director, CMS, NALSAR University of Law, Hyderabad" },
  { name: "Dr Rajendran Govender", title: "Commissioner, Cultural, Religious and Linguistic Rights Commission", affiliation: "Republic of South Africa; Social Anthropologist; Ford and IBSA Fellow" },
  { name: "Dr. Ushadevi", title: "Professor and Chairperson, Department of Physics", affiliation: "Bangalore University" },
  { name: "Prof. S. Y. Surendra Kumar", title: "Professor and Chairperson, Department of Political Science", affiliation: "Bangalore University, Bengaluru", bio: "Professor of Political Science with 20 years of teaching experience. He earned his M.Phil. and Ph.D. in South Asian Studies at Jawaharlal Nehru University, New Delhi, and has authored four books, over 25 book chapters, and more than 40 research articles. His research areas are public policy, South Asian security, and Indian foreign policy toward the United States and China." },
  { name: "Dr Kwadwo Boateng", title: "Principal Consultant, Management Development and Productivity Institute (MDPI)", affiliation: "Ghana", bio: "An authority in financial risk analysis, sustainable finance, and ESG frameworks across Africa. He holds a Ph.D. in Management (Finance) and has authored over 16 peer-reviewed publications as a certified Publons Academy peer reviewer." },
  { name: "Dr Rajesh M V", title: "Dean of Commerce", affiliation: "Loyola Degree College, Bangalore" },
  { name: "Dr Vinod Sharma", title: "Professor in Computer Science; Director, Ramnagar Campus", affiliation: "University of Jammu", bio: "Formerly Director of the Poonch Campus and Head of Department, with 18 years of research experience and membership of Academic Councils and Boards of Studies across several Indian universities." },
  { name: "Dr Bishwajit Paul", title: "UGC Assistant Professor, Department of Chemistry", affiliation: "Bangalore University", bio: "Completed his PhD at New York University under Prof. Kent Kirshenbaum, with postdoctoral work at the University of Michigan and the Broad Institute. His group studies biomimetic peptidic foldamers and noncovalent interactions. He has published more than 25 international research articles, a book, and three book chapters." },
  { name: "Dr. Lubna Ambreen", title: "Associate Professor; Coordinator, Ph.D. Program (Management)", affiliation: "CMS B-School, JAIN (Deemed-to-be University)" },
  { name: "Dr Sajid Alvi", title: "Professor and Director", affiliation: "Dnyansagar Institute of Management and Research, Pune" },
  { name: "Dr Fakru Khan", title: "Editorial Board Member", affiliation: "—" },
];

const ASSIST: Member[] = [
  { name: "Ramesh Krishna", title: "Lecturer, Business Administration", affiliation: "University of Technology and Applied Sciences, Nizwa, Oman" },
  { name: "Praveen Kumar H", title: "Data Science Senior Lead (VP)", affiliation: "Wells Fargo", bio: "A data-driven professional with 14 years of experience in data science and analytics across pharma, retail, and financial services." },
  { name: "Amaresh Gadagi", title: "Manager, Customer Service", affiliation: "LKQ India Private Limited, Bangalore", bio: "Over 15 years of experience in business and commercial operations and analytics; industry representative on the IQAC committee at Bangalore University." },
  { name: "Shaan", title: "Editorial Assistance", affiliation: "—" },
];

function initials(name: string) {
  const parts = name.replace(/^(Prof\.|Dr\.?|Mr\.?|Ms\.?)\s+/i, "").split(/\s+/);
  return ((parts[0]?.[0] ?? "") + (parts[parts.length - 1]?.[0] ?? "")).toUpperCase();
}

function MemberRow({ m }: { m: Member }) {
  return (
    <div className="memberrow" style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: 22, padding: "24px 0", borderTop: `1px solid ${T.rule}`, alignItems: "start" }}>
      <div>
        {m.photo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={m.photo} alt={m.name} style={{ width: 120, height: 120, objectFit: "cover", border: `1px solid ${T.rule}`, filter: "grayscale(1)" }} />
        ) : (
          <div style={{ width: 120, height: 120, border: `1px solid ${T.g300}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 34, color: T.muted, background: T.g100 }}>{initials(m.name)}</div>
        )}
      </div>
      <div>
        <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 21, margin: "0 0 5px", lineHeight: 1.2 }}>{m.name}</h3>
        <div style={{ fontFamily: T.sans, fontSize: 13.5, color: T.ink, lineHeight: 1.5 }}>{m.title}</div>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, lineHeight: 1.5, marginTop: 2 }}>{m.affiliation}</div>
        {m.bio && <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.6, color: "#333", margin: "12px 0 0" }}>{m.bio}</p>}
      </div>
    </div>
  );
}

export default function EditorialBoard() {
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>Editorial Board</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 10px" }}>Editorial Board</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 20px" }}>
        The journal is guided by an international board of senior academics and practitioners across the sciences, management, and the social sciences. All editorial correspondence is handled through the journal&rsquo;s editorial office.
      </p>

      <h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", color: T.ink, margin: "26px 0 0", borderBottom: `2px solid ${T.ink}`, paddingBottom: 8 }}>Editorial Team</h2>
      {TEAM.map((m) => <MemberRow key={m.name} m={m} />)}

      <h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", color: T.ink, margin: "40px 0 0", borderBottom: `2px solid ${T.ink}`, paddingBottom: 8 }}>Editorial Assistance</h2>
      {ASSIST.map((m) => <MemberRow key={m.name} m={m} />)}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- shared prose-page helper + compliance pages
cat > src/lib/legal.tsx << 'IJRI_EOF'
import React from "react";
import { T, Eyebrow } from "@/lib/ui";

export function LegalPage({ eyebrow, title, icon, children }: { eyebrow: string; title: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}>{icon}<Eyebrow inverse>{eyebrow}</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 20px" }}>{title}</h1>
      <div style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.62, color: "#1c1c1c" }}>{children}</div>
    </main>
  );
}

export function H({ children }: { children: React.ReactNode }) {
  return <h2 style={{ fontFamily: T.serif, fontSize: 22, margin: "28px 0 8px" }}>{children}</h2>;
}
IJRI_EOF

cat > src/app/about/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconBook } from "@/lib/icons";
export default function About() {
  return (
    <LegalPage eyebrow="About" title="About the Journal" icon={<IconBook size={22} />}>
      <p>The International Journal of Research and Innovation (IJRI) is a multidisciplinary, double-blind peer-reviewed research journal. It publishes original research, reviews, and scholarly commentary across the sciences, engineering, management, and the social sciences.</p>
      <H>Peer review</H>
      <p>Every submission is evaluated under a double-blind process by members of the editorial board. Accepted articles are published by the Editor-in-Chief with the reviewing editors and bibliographic details recorded on each article.</p>
      <H>Access</H>
      <p>Abstracts and article metadata are freely available to all readers. Full texts are available to subscribers and to authorised members of the journal.</p>
      <H>Publisher</H>
      <p>IJRI is published online at ijrein.org. The journal maintains a permanent editorial office for all correspondence relating to submissions, subscriptions, and editorial policy.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/aims-scope/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconLayers } from "@/lib/icons";
export default function AimsScope() {
  return (
    <LegalPage eyebrow="Aims & Scope" title="Aims & Scope" icon={<IconLayers size={22} />}>
      <p>IJRI aims to advance rigorous, original scholarship and to make it accessible to researchers, practitioners, and policymakers. As a multidisciplinary journal, it welcomes work that is methodologically sound and of clear significance to its field.</p>
      <H>Subject areas</H>
      <p>The journal publishes across areas including, but not limited to, computer and information science, medicine and public health, engineering, economics and management, materials science, and the social sciences.</p>
      <H>Article types</H>
      <p>Original research articles, systematic reviews, and scholarly commentary are considered. All submissions must be prepared in accordance with the journal&rsquo;s guidelines for authors and undergo double-blind peer review.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/ethics/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconShield } from "@/lib/icons";
export default function Ethics() {
  return (
    <LegalPage eyebrow="Publication Ethics" title="Publication Ethics & Malpractice Statement" icon={<IconShield size={22} />}>
      <p>IJRI is committed to upholding the highest standards of publication ethics and follows the principles set out by the Committee on Publication Ethics (COPE).</p>
      <H>Authors</H>
      <p>Authors must ensure that their work is original, that all sources are properly cited, and that the manuscript has not been published elsewhere or is under consideration by another journal. All listed authors must have made a genuine contribution, and any conflicts of interest must be declared.</p>
      <H>Plagiarism</H>
      <p>Submissions are screened for similarity in line with UGC plagiarism guidelines. Manuscripts found to contain plagiarised or fabricated content are rejected, and published articles found in violation are subject to correction or retraction.</p>
      <H>Editors and reviewers</H>
      <p>Editors evaluate manuscripts solely on scholarly merit, without regard to the authors&rsquo; identity, and maintain the confidentiality of the review process. Reviewers must disclose competing interests and decline review where a conflict exists.</p>
      <H>Corrections and retractions</H>
      <p>The journal will publish corrections, expressions of concern, or retractions where warranted, in a transparent and timely manner.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/copyright/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconScale } from "@/lib/icons";
export default function Copyright() {
  return (
    <LegalPage eyebrow="Copyright" title="Copyright & Licensing" icon={<IconScale size={22} />}>
      <p>Articles published in IJRI are protected by copyright. All rights are reserved unless otherwise stated.</p>
      <H>Rights</H>
      <p>Copyright in each article is held by the respective authors and the journal as recorded at publication. Full texts and PDFs are made available to subscribers and authorised users; redistribution without permission is not permitted.</p>
      <H>Permitted use</H>
      <p>Readers may cite published articles with appropriate attribution, including the journal name, volume, issue, and page numbers as shown on each article. Requests for reuse beyond fair dealing should be directed to the editorial office.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/privacy/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconLock } from "@/lib/icons";
export default function Privacy() {
  return (
    <LegalPage eyebrow="Privacy" title="Privacy Policy" icon={<IconLock size={22} />}>
      <p>This policy explains how IJRI handles personal information collected through ijrein.org.</p>
      <H>Information we collect</H>
      <p>We collect the information you provide when you register an account or submit a manuscript, such as your name, email address, and affiliation. We also collect limited technical information necessary to operate the site securely.</p>
      <H>How we use it</H>
      <p>Personal information is used to manage accounts, process submissions and subscriptions, and communicate with authors, reviewers, and subscribers. We do not sell personal information.</p>
      <H>Your rights</H>
      <p>You may request access to, correction of, or deletion of your personal information by contacting the editorial office.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/terms/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconDoc } from "@/lib/icons";
export default function Terms() {
  return (
    <LegalPage eyebrow="Terms" title="Terms & Conditions" icon={<IconDoc size={22} />}>
      <p>By using ijrein.org you agree to these terms.</p>
      <H>Use of the site</H>
      <p>Content is provided for scholarly and personal use. Automated harvesting, redistribution of full texts, or circumvention of access controls is prohibited.</p>
      <H>Accounts and subscriptions</H>
      <p>You are responsible for maintaining the confidentiality of your account. Subscription access is granted to the account holder and may not be shared.</p>
      <H>Disclaimer</H>
      <p>The views expressed in published articles are those of the authors and do not necessarily reflect those of the journal or its editorial board.</p>
    </LegalPage>
  );
}
IJRI_EOF

cat > src/app/contact/page.tsx << 'IJRI_EOF'
import { LegalPage, H } from "@/lib/legal";
import { IconMail } from "@/lib/icons";
export default function Contact() {
  return (
    <LegalPage eyebrow="Contact" title="Contact" icon={<IconMail size={22} />}>
      <p>All correspondence relating to submissions, subscriptions, and editorial policy should be directed to the journal&rsquo;s editorial office.</p>
      <H>Editorial office</H>
      <p>Email: editor@ijrein.org<br />Web: ijrein.org</p>
      <p style={{ fontFamily: "inherit", fontSize: 14, color: "#6b6b6b" }}>Please update this address with your official editorial office contact and postal address before applying for the ISSN, as the ISSN office requires a verifiable publisher contact.</p>
    </LegalPage>
  );
}
IJRI_EOF

echo ""
echo "Stage 2b UI written. Now run:"
echo "  npm run build"
echo "  git add . && git commit -m 'Stage 2b UI: footer, compliance pages, icons, board' && git push origin main"
