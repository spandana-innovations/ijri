#!/usr/bin/env bash
# ==========================================================================
# IJRI — branding + editorial content.
#   - logo in masthead, white logo in footer, favicon
#   - Editorial Board page (from your Editorial Team doc, photo slots)
#   - Guidelines for Authors page (from your doc)
# Assets (logos, favicon, /team) come from the zip you unzipped into the repo.
# Run in the repo:  bash build-branding.sh
# ==========================================================================
set -euo pipefail
echo "Applying branding + content..."
mkdir -p src/app/editorial-board src/app/for-authors

# ---------------------------------------------------------------- layout with logo + footer logo + favicon
cat > src/app/layout.tsx << 'IJRI_EOF'
import Link from "next/link";
import { T } from "@/lib/ui";

export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary, double-blind peer-reviewed research journal.",
};

const CURRENT = "Volume 1, Issue 1 · July 2026";
const NAV: [string, string][] = [
  ["/", "Home"],
  ["/archives", "Archives"],
  ["/editorial-board", "Editorial Board"],
  ["/for-authors", "For Authors"],
];

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, background: T.paper, color: T.ink }}>
        <style>{`
          * { box-sizing: border-box; }
          a { color: inherit; text-decoration: none; }
          .nav a:hover { background:#ececec; }
          .cardtitle { text-decoration: underline transparent; text-underline-offset: 3px; transition: text-decoration-color .15s; }
          a:hover .cardtitle { text-decoration-color: ${T.ink}; }
          .body h2 { font-family:${T.serif}; font-size:22px; margin:28px 0 10px; }
          .body p { font-family:${T.serif}; font-size:18.5px; line-height:1.68; margin:0 0 20px; color:#1a1a1a; }
          .body blockquote { font-family:${T.serif}; font-style:italic; border-left:3px solid ${T.ink}; margin:24px 0; padding:4px 0 4px 18px; color:#333; }
          .body p:first-of-type::first-letter { font-family:${T.serif}; float:left; font-size:62px; line-height:.82; padding:6px 10px 0 0; font-weight:600; }
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} }
        `}</style>

        <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
          <div style={{ borderBottom: `1px solid ${T.rule}` }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
              <span>e-ISSN: applied for</span><span>Double-blind peer-reviewed</span>
            </div>
          </div>
          <div style={{ maxWidth: 1120, margin: "0 auto", padding: "20px 20px 14px", textAlign: "center" }}>
            <Link href="/" style={{ display: "inline-block" }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo-stacked.png" alt="International Journal of Research and Innovation" style={{ height: "clamp(64px,11vw,96px)", width: "auto" }} />
            </Link>
          </div>
          <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
              Current issue · {CURRENT}
            </div>
          </div>
          <nav className="nav" style={{ background: T.faint }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
              {NAV.map(([href, label]) => (
                <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
              ))}
            </div>
          </nav>
        </header>

        {children}

        <footer style={{ borderTop: `1px solid ${T.ink}`, background: T.ink, marginTop: 40 }}>
          <div style={{ maxWidth: 1120, margin: "0 auto", padding: "34px 20px", textAlign: "center" }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 30, width: "auto", opacity: 0.95 }} />
            <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: "#9a9a9a", marginTop: 16 }}>
              ijrein.org · e-ISSN applied for · © 2026 International Journal of Research and Innovation
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- editorial board page
cat > src/app/editorial-board/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";

type Member = { name: string; roles: string[]; email?: string; bio?: string; photo?: string };

const TEAM: Member[] = [
  { name: "Prof. Vidyadhar Reddy Aileni", roles: ["Former Dean, Faculty of Management, Osmania University", "Former Director, CMS, NALSAR University of Law, Hyderabad", "Former Vice President, Brand Enterprises Pvt Ltd, Hyderabad"], email: "prof.avreddy@gmail.com" },
  { name: "Dr Rajendran Govender", roles: ["Commissioner, Cultural, Religious and Linguistic Rights Commission, South Africa", "Social Anthropologist; Ford and IBSA Fellow", "Board Member, Pan South African Language Board (PANSALB)", "Africa Coordinator, Advocacy Unified Network (The Hague)", "Chairman, Africa Kingdom Diaspora Alliance", "Board Member, Journalists and Writers Foundation (New York)"] },
  { name: "Dr. Ushadevi", roles: ["Professor and Chairperson, Department of Physics", "Bangalore University"] },
  { name: "Prof. S. Y. Surendra Kumar, PhD", roles: ["Professor and Chairperson, Department of Political Science", "Bangalore University, Jnana Bharathi Campus, Bengaluru-560056"], email: "surendradps@bub.ernet.in", bio: `Professor and Chairman at the Department of Political Science, Bangalore University, with 20 years of teaching experience at the PG level. He earned his M.Phil. and Ph.D. in South Asian Studies at the School of International Studies, Jawaharlal Nehru University, New Delhi, and has received the Mahbub-ul-Haq Research Award and a Short Duration Fellowship. He has four books to his credit — most recently Empowering the Marginalized Communities in India: The Impact of Higher Education (SAGE, 2021) — over 25 book chapters, and more than 40 research articles. His research areas are public policy, South Asian security, and Indian foreign policy toward the United States and China.` },
  { name: "Dr Kwadwo Boateng, PhD", roles: ["Principal Consultant, Management Development and Productivity Institute (MDPI), Ghana"], bio: `An expert in credit, environmental and social risk management, sustainable finance, and banking. He holds a Ph.D. in Management (Finance) from Bangalore University and degrees in Financial Management from the Business University of Costa Rica. A leading authority in financial risk analysis, digital banking, financial inclusion, and ESG frameworks across Africa, he consults for organisations including the Vanuatu Trade Commission and the Africa Diaspora Central Bank. A certified Publons Academy peer reviewer, he has authored over 16 peer-reviewed publications.` },
  { name: "Dr Rajesh M V", roles: ["B.Com, MBA, PGDIB, Ph.D.", "Dean of Commerce, Loyola Degree College, Bangalore-560076"], email: "phdrajesh08@gmail.com" },
  { name: "Dr Vinod Sharma", roles: ["Professor in Computer Science", "Director, Ramnagar Campus, University of Jammu (2021–present)", "Director, Poonch Campus, University of Jammu (2018–2020)", "Head of Department (2015–2018)"], bio: `Member of the Academic Council and Board of Studies at several universities in India, with 18 years of research experience.` },
  { name: "Dr Bishwajit Paul", roles: ["UGC Assistant Professor, Department of Chemistry", "Bangalore University, Bangalore-560056"], bio: `Completed his PhD at New York University in 2012 under Prof. Kent Kirshenbaum, followed by postdoctoral positions at the University of Michigan, Ann Arbor and at Brigham Women's Hospital and The Broad Institute. He began his independent career in 2016 under the UGC Faculty Recharge Program. His group studies biomimetic peptidic foldamers and noncovalent interactions such as halogen bonding and weak hydrogen bonding. He has published more than 25 international research articles, one book, and three book chapters, and writes for Resonance and Chemistry World (RSC).` },
  { name: "Dr. Lubna Ambreen", roles: ["Associate Professor; Program Coordinator, ENVC Area", "Coordinator, Ph.D. Program (Management), CMS B-School", "Faculty of Management Studies, JAIN (Deemed-to-be University)"], email: "lubnaambreen27@gmail.com" },
  { name: "Dr Sajid Alvi", roles: ["Professor and Director", "Dnyansagar Institute of Management and Research, Pune"] },
  { name: "Dr Fakru Khan", roles: [] },
];

const ASSIST: Member[] = [
  { name: "Ramesh Krishna", roles: ["Lecturer, Business Administration", "University of Technology and Applied Sciences, Nizwa, Oman"] },
  { name: "Praveen Kumar H", roles: ["Data Science Senior Lead (VP), Wells Fargo"], bio: `A data-driven professional with 14 years of experience in data science, analytics, solution building, and reporting across pharma, retail, and financial services, applying machine learning, process improvement, and automation to real-world business problems.` },
  { name: "Amaresh Gadagi", roles: ["Manager, Customer Service, LKQ India Private Limited", "Bannerghatta Main Road, Bangalore-560076"], bio: `Over 15 years of experience in business and commercial operations, finance, fleet operations analytics, and client servicing across the BPO and captive industry, having worked with Capgemini, Xerox, and LKQ Corporation. Currently an industry representative on the IQAC committee at Bangalore University.` },
  { name: "Shaan", roles: [] },
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
          <div style={{ width: 120, height: 120, border: `1px solid ${T.ink}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 34, color: T.ink, background: T.faint }}>{initials(m.name)}</div>
        )}
      </div>
      <div>
        <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 21, margin: "0 0 6px", lineHeight: 1.2 }}>{m.name}</h3>
        {m.roles.map((r, i) => (
          <div key={i} style={{ fontFamily: T.sans, fontSize: 13, color: i === 0 ? T.ink : T.muted, lineHeight: 1.5 }}>{r}</div>
        ))}
        {m.email && <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 6 }}>{m.email}</div>}
        {m.bio && <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.6, color: "#333", margin: "12px 0 0" }}>{m.bio}</p>}
      </div>
    </div>
  );
}

export default function EditorialBoard() {
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Editorial Board</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 10px" }}>Editorial Board</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 20px" }}>
        The journal is guided by an international board of senior academics and practitioners across the sciences, management, and the social sciences.
      </p>

      <h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", color: T.ink, margin: "26px 0 0", borderBottom: `2px solid ${T.ink}`, paddingBottom: 8 }}>Editorial Team</h2>
      {TEAM.map((m) => <MemberRow key={m.name} m={m} />)}

      <h2 style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.12em", textTransform: "uppercase", color: T.ink, margin: "40px 0 0", borderBottom: `2px solid ${T.ink}`, paddingBottom: 8 }}>Editorial Assistance</h2>
      {ASSIST.map((m) => <MemberRow key={m.name} m={m} />)}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- guidelines for authors page
cat > src/app/for-authors/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";

const SECTIONS: { h: string; body: string; list?: string[] }[] = [
  { h: "Title", body: "The title must help researchers find and cite your article, so it should convey the meaning of the content precisely. Keep it appealing, concise, and clearly indicative of the subject matter presented." },
  { h: "Abstract", body: "The abstract should contain, specifically:", list: ["The stated purpose of the study or research", "A brief account of the methodology undertaken", "The findings of the study", "The conclusions of the research conducted", "Any trial registry name, registration number, or URL, as applicable"] },
  { h: "Keywords", body: "Keywords mirror the topic of the study and are mandatory; they allow identification of the core and principal concepts involved in the work." },
  { h: "Acknowledgements", body: "Credit must be acknowledged wherever it is due. Authors are required to follow the APA 7 style for referencing." },
  { h: "Author contributions statement", body: "State each author's contribution to the development of the article, whether the work has a single author or multiple authors." },
  { h: "Statements and declarations", body: "Declarations such as the 'No conflict of interest' statement must be signed by the sole author, or by each author in the case of multiple authors." },
];

export default function ForAuthors() {
  return (
    <main style={{ maxWidth: 760, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>For Authors</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 10px" }}>Guidelines for Authors</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 26px" }}>
        Please prepare your manuscript according to the following requirements before submission. All submissions undergo double-blind peer review.
      </p>
      {SECTIONS.map((s) => (
        <section key={s.h} style={{ padding: "18px 0", borderTop: `1px solid ${T.rule}` }}>
          <h2 style={{ fontFamily: T.serif, fontSize: 21, margin: "0 0 8px" }}>{s.h}</h2>
          <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.6, color: "#222", margin: 0 }}>{s.body}</p>
          {s.list && (
            <ul style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.6, color: "#222", margin: "10px 0 0", paddingLeft: 22 }}>
              {s.list.map((li) => <li key={li} style={{ marginBottom: 4 }}>{li}</li>)}
            </ul>
          )}
        </section>
      ))}
      <p style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 24, lineHeight: 1.6 }}>
        Referencing follows APA 7. Manuscripts are checked for similarity in line with UGC plagiarism guidelines before review.
      </p>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Branding + content written. Now run:"
echo "  npm run build"
echo "  git add . && git commit -m 'Branding: logo, favicon, editorial board, author guidelines' && git push origin main"
