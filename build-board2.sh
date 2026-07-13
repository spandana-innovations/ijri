#!/usr/bin/env bash
# ==========================================================================
# IJRI — restore the previous editorial board page (curated static version:
# Dr Cynthia Menezes Prabhu as Editor-in-Chief, country flags, full bios).
# No profile pictures — exactly as it was before the DB-driven rebuild.
# Run in repo:  bash build-board2.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
mkdir -p src/app/editorial-board

cat > src/app/editorial-board/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type Member = { name: string; title: string; affiliation: string; country: string; flag: string; bio: string; photo?: string; chief?: boolean };

const BOARD: Member[] = [
  { name: "Dr Cynthia Menezes Prabhu", title: "Editor-in-Chief · Professor, Department of Management Studies", affiliation: "Bangalore University, Bengaluru", country: "India", flag: "🇮🇳", chief: true, bio: "Professor of Management Studies with an MBA and PhD and over 25 years of teaching experience, including 15 years at the postgraduate level. She has produced five PhDs and currently guides eight PhD scholars, with numerous national and international publications, and has served as acting Vice-Chancellor of Bangalore University. Her research interests span International Business, Quantitative Techniques, and Systems." },
  { name: "Prof. Vidyadhar Reddy Aileni", title: "Former Dean, Faculty of Management", affiliation: "Osmania University; former Director, CMS, NALSAR University of Law, Hyderabad", country: "India", flag: "🇮🇳", bio: "A senior figure in management education and administration, with leadership experience spanning academia and industry." },
  { name: "Dr Rajendran Govender", title: "Commissioner, Cultural, Religious and Linguistic Rights Commission", affiliation: "Republic of South Africa", country: "South Africa", flag: "🇿🇦", bio: "A social anthropologist and Ford and IBSA Fellow whose work focuses on cultural, religious, and linguistic rights and community development." },
  { name: "Dr. Ushadevi", title: "Professor and Chairperson, Department of Physics", affiliation: "Bangalore University", country: "India", flag: "🇮🇳", bio: "An academic physicist leading the Department of Physics, with research and teaching interests across the physical sciences." },
  { name: "Prof. S. Y. Surendra Kumar", title: "Professor and Chairperson, Department of Political Science", affiliation: "Bangalore University, Bengaluru", country: "India", flag: "🇮🇳", bio: "Professor of Political Science with 20 years of teaching experience. He earned his M.Phil. and Ph.D. in South Asian Studies at Jawaharlal Nehru University and has authored four books, over 25 book chapters, and more than 40 research articles. His research areas are public policy, South Asian security, and Indian foreign policy toward the United States and China." },
  { name: "Dr Kwadwo Boateng", title: "Principal Consultant, Management Development and Productivity Institute (MDPI)", affiliation: "Accra, Ghana", country: "Ghana", flag: "🇬🇭", bio: "An authority in financial risk analysis, sustainable finance, and ESG frameworks across Africa. He holds a Ph.D. in Management (Finance) and has authored over 16 peer-reviewed publications as a certified Publons Academy peer reviewer." },
  { name: "Dr Rajesh M V", title: "Dean of Commerce", affiliation: "Loyola Degree College, Bangalore", country: "India", flag: "🇮🇳", bio: "An academic leader in commerce education with interests in commerce, finance, and management studies." },
  { name: "Dr Vinod Sharma", title: "Professor in Computer Science; Director, Ramnagar Campus", affiliation: "University of Jammu", country: "India", flag: "🇮🇳", bio: "Formerly Director of the Poonch Campus and Head of Department, with 18 years of research experience and membership of Academic Councils and Boards of Studies across several Indian universities." },
  { name: "Dr Bishwajit Paul", title: "UGC Assistant Professor, Department of Chemistry", affiliation: "Bangalore University", country: "India", flag: "🇮🇳", bio: "Completed his PhD at New York University under Prof. Kent Kirshenbaum, with postdoctoral work at the University of Michigan and the Broad Institute. His group studies biomimetic peptidic foldamers and noncovalent interactions, and he has published more than 25 international research articles, a book, and three book chapters." },
  { name: "Dr. Lubna Ambreen", title: "Associate Professor; Coordinator, Ph.D. Program (Management)", affiliation: "CMS B-School, JAIN (Deemed-to-be University)", country: "India", flag: "🇮🇳", bio: "A management academic coordinating doctoral research, with interests in management studies and environmental concerns." },
  { name: "Dr Sajid Alvi", title: "Professor and Director", affiliation: "Dnyansagar Institute of Management and Research, Pune", country: "India", flag: "🇮🇳", bio: "An academic administrator and management educator directing an institute of management and research." },
  { name: "Dr Fakru Khan", title: "Editorial Board Member", affiliation: "India", country: "India", flag: "🇮🇳", bio: "A member of the editorial board contributing subject expertise to the review process." },
];

const ASSIST: Member[] = [
  { name: "Ramesh Krishna", title: "Lecturer, Business Administration", affiliation: "University of Technology and Applied Sciences, Nizwa, Oman", country: "Oman", flag: "🇴🇲", bio: "Provides editorial and academic support with a background in business administration." },
  { name: "Praveen Kumar H", title: "Data Science Senior Lead (VP)", affiliation: "Wells Fargo", country: "India", flag: "🇮🇳", bio: "Supports the journal with data science and analytics expertise across pharma, retail, and financial services." },
  { name: "Amaresh Gadagi", title: "Manager, Customer Service", affiliation: "LKQ India Private Limited, Bangalore", country: "India", flag: "🇮🇳", bio: "Contributes operational and business support, with experience across commercial operations and analytics." },
  { name: "Shaan", title: "Editorial Assistance", affiliation: "India", country: "India", flag: "🇮🇳", bio: "Provides editorial and operational assistance to the board." },
];

function initials(name: string) {
  const p = name.replace(/^(Prof\.|Dr\.?|Mr\.?|Ms\.?)\s+/i, "").split(/\s+/);
  return ((p[0]?.[0] ?? "") + (p[p.length - 1]?.[0] ?? "")).toUpperCase();
}

function BoardCard({ m }: { m: Member }) {
  return (
    <div className="memberrow" style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: 22, padding: "24px 0", borderTop: `1px solid ${T.rule}`, alignItems: "start" }}>
      <div>
        {m.photo ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={m.photo} alt={m.name} style={{ width: 120, height: 120, objectFit: "cover", border: `1px solid ${T.rule}`, filter: "grayscale(1)" }} />
        ) : (
          <div style={{ width: 120, height: 120, border: m.chief ? `2px solid ${T.ink}` : `1px solid ${T.g300}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 34, color: m.chief ? T.ink : T.muted, background: m.chief ? T.paper : T.g100 }}>{initials(m.name)}</div>
        )}
      </div>
      <div>
        <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
          <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 21, margin: 0, lineHeight: 1.2 }}>{m.name}</h3>
          <span title={m.country} style={{ fontSize: 18, lineHeight: 1 }}>{m.flag}</span>
        </div>
        <div style={{ fontFamily: T.sans, fontSize: 13.5, color: T.ink, lineHeight: 1.5, marginTop: 4 }}>{m.title}</div>
        <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, lineHeight: 1.5 }}>{m.affiliation} · {m.country}</div>
        <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.6, color: "#8a8a8a", margin: "10px 0 0", maxWidth: 640 }}>{m.bio}</p>
      </div>
    </div>
  );
}

export default function EditorialBoard() {
  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>Editorial Board</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 10px" }}>Editorial Board</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 8px" }}>
        The board comprises senior academics and practitioners who set editorial policy and conduct double-blind peer review. All correspondence is handled through the journal&rsquo;s editorial office.
      </p>
      {BOARD.map((m) => <BoardCard key={m.name} m={m} />)}

      <section style={{ marginTop: 48, background: T.g100, border: `1px solid ${T.rule}`, padding: "8px 24px 24px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink, marginTop: 20 }}><IconUsers size={20} /><Eyebrow>Editorial Assistance</Eyebrow></div>
        <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.55, color: T.muted, margin: "10px 0 4px" }}>The following provide editorial, technical, and operational support to the board.</p>
        <div className="cardgrid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0 26px" }}>
          {ASSIST.map((m) => (
            <div key={m.name} style={{ padding: "16px 0", borderTop: `1px solid ${T.g300}` }}>
              <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
                <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 18, margin: 0 }}>{m.name}</h3>
                <span title={m.country} style={{ fontSize: 15 }}>{m.flag}</span>
              </div>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.ink, marginTop: 2 }}>{m.title}</div>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>{m.affiliation}</div>
              <p style={{ fontFamily: T.sans, fontSize: 12.5, lineHeight: 1.55, color: "#8a8a8a", margin: "8px 0 0" }}>{m.bio}</p>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
IJRI_EOF

echo "Previous editorial board restored. Now run:  npm run build"
