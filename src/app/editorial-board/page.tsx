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
