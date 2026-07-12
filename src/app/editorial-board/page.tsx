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
