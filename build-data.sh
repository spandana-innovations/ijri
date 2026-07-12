#!/usr/bin/env bash
# ==========================================================================
# IJRI — data layer: approval field, expanded seed (real editorial team as
# reviewers + more articles), separated Editorial Board / Assistance page.
# Run in repo:  bash build-data.sh  ->  npx prisma db push  ->  npm run seed
# ==========================================================================
set -euo pipefail
echo "Data layer: schema, seed, board..."
mkdir -p prisma src/app/editorial-board

# ---------------------------------------------------------------- schema (adds User.approved + image)
cat > prisma/schema.prisma << 'IJRI_EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum Role {
  AUTHOR
  EDITOR
  CHIEF_EDITOR
  ADMIN
}

enum ArticleStatus {
  SUBMITTED
  UNDER_REVIEW
  REVIEWED
  PUBLISHED
  REJECTED
}

enum Recommendation {
  ACCEPT
  MINOR_REVISION
  MAJOR_REVISION
  REJECT
}

enum PlanType {
  MONTHLY
  ANNUAL
  PRINT_DIGITAL
  SECTION
}

enum SubscriptionStatus {
  ACTIVE
  EXPIRED
  CANCELLED
}

model User {
  id            String   @id @default(cuid())
  email         String   @unique
  name          String
  role          Role     @default(AUTHOR)
  approved      Boolean  @default(false)
  affiliation   String?
  image         String?
  passwordHash  String?
  createdAt     DateTime @default(now())
  submitted     Article[]         @relation("SubmittedBy")
  reviews       Review[]
  decisions     Article[]         @relation("DecidedBy")
  subscriptions Subscription[]
  purchases     ArticlePurchase[]
}

model Section {
  id       String         @id @default(cuid())
  name     String         @unique
  slug     String         @unique
  articles Article[]
  subs     Subscription[]
}

model Issue {
  id          String    @id @default(cuid())
  volume      Int
  number      Int
  label       String
  isCurrent   Boolean   @default(false)
  publishedAt DateTime?
  articles    Article[]

  @@unique([volume, number])
}

model Article {
  id           String        @id @default(cuid())
  title        String
  abstract     String
  bodyHtml     String?       @db.Text
  coverImage   String?
  authorNames  String
  affiliation  String?
  status       ArticleStatus @default(SUBMITTED)
  section      Section       @relation(fields: [sectionId], references: [id])
  sectionId    String
  issue        Issue?        @relation(fields: [issueId], references: [id])
  issueId      String?
  startPage    Int?
  endPage      Int?
  doi          String?       @unique
  pdfKey       String?
  submittedBy   User     @relation("SubmittedBy", fields: [submittedById], references: [id])
  submittedById String
  chiefEditor   User?    @relation("DecidedBy", fields: [chiefEditorId], references: [id])
  chiefEditorId String?
  decidedAt     DateTime?
  reviews      Review[]
  purchases    ArticlePurchase[]
  createdAt    DateTime  @default(now())
  publishedAt  DateTime?

  @@index([status])
  @@index([issueId])
}

model Review {
  id             String         @id @default(cuid())
  article        Article        @relation(fields: [articleId], references: [id])
  articleId      String
  editor         User           @relation(fields: [editorId], references: [id])
  editorId       String
  recommendation Recommendation
  comments       String?        @db.Text
  createdAt      DateTime       @default(now())

  @@unique([articleId, editorId])
}

model Subscription {
  id        String             @id @default(cuid())
  user      User               @relation(fields: [userId], references: [id])
  userId    String
  plan      PlanType
  status    SubscriptionStatus @default(ACTIVE)
  print     Boolean            @default(false)
  section   Section?           @relation(fields: [sectionId], references: [id])
  sectionId String?
  startsAt  DateTime           @default(now())
  endsAt    DateTime
  createdAt DateTime           @default(now())

  @@index([userId, status])
}

model ArticlePurchase {
  id        String   @id @default(cuid())
  user      User     @relation(fields: [userId], references: [id])
  userId    String
  article   Article  @relation(fields: [articleId], references: [id])
  articleId String
  createdAt DateTime @default(now())

  @@unique([userId, articleId])
}
IJRI_EOF

# ---------------------------------------------------------------- expanded seed
cat > prisma/seed.ts << 'IJRI_EOF'
import { PrismaClient, Role } from "@prisma/client";
import bcrypt from "bcryptjs";
const prisma = new PrismaClient();

const SECTIONS = [
  "Computer Science", "Medicine & Public Health", "Engineering",
  "Economics", "Materials Science", "Social Science",
];
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
const DEFAULT_PASSWORD = "ChangeMe#2026";

const FIG = (n: number, cap: string) =>
  `<figure style="margin:26px 0"><div style="border:1px solid #e4e4e4;background:#f6f6f6;height:200px;display:flex;align-items:center;justify-content:center;font-family:sans-serif;font-size:12px;letter-spacing:.1em;text-transform:uppercase;color:#6b6b6b">Figure ${n}</div><figcaption style="font-family:sans-serif;font-size:12px;color:#6b6b6b;margin-top:8px"><strong>Fig. ${n}.</strong> ${cap}</figcaption></figure>`;

const body = (p: string[], figCap: string) =>
  `<p>${p[0]}</p>${FIG(1, figCap)}<h2>Methods</h2><p>${p[1]}</p><h2>Results and discussion</h2><p>${p[2]}</p><blockquote>These findings suggest a path that is both practical and reproducible in resource-constrained settings.</blockquote><h2>Conclusion</h2><p>${p[3] ?? "Further work will extend these results to larger and more diverse datasets."}</p>`;

// Editorial team as reviewer/editor accounts
const STAFF: { email: string; name: string; role: Role; affiliation?: string }[] = [
  { email: "admin@ijrein.org", name: "IJRI Admin", role: "ADMIN" },
  { email: "vreddy@ijrein.org", name: "Prof. Vidyadhar Reddy Aileni", role: "CHIEF_EDITOR", affiliation: "Osmania University" },
  { email: "ushadevi@ijrein.org", name: "Dr. Ushadevi", role: "EDITOR", affiliation: "Bangalore University" },
  { email: "surendra@ijrein.org", name: "Prof. S. Y. Surendra Kumar", role: "EDITOR", affiliation: "Bangalore University" },
  { email: "boateng@ijrein.org", name: "Dr Kwadwo Boateng", role: "EDITOR", affiliation: "MDPI, Ghana" },
  { email: "rajesh@ijrein.org", name: "Dr Rajesh M V", role: "EDITOR", affiliation: "Loyola Degree College" },
  { email: "vsharma@ijrein.org", name: "Dr Vinod Sharma", role: "EDITOR", affiliation: "University of Jammu" },
  { email: "bpaul@ijrein.org", name: "Dr Bishwajit Paul", role: "EDITOR", affiliation: "Bangalore University" },
  { email: "lubna@ijrein.org", name: "Dr. Lubna Ambreen", role: "EDITOR", affiliation: "JAIN University" },
  { email: "govender@ijrein.org", name: "Dr Rajendran Govender", role: "EDITOR", affiliation: "CRL Commission, South Africa" },
];

type A = { section: string; title: string; authors: string; aff: string; start: number; end: number; reviewers: string[]; abstract: string; figCap: string; paras: string[] };
const ARTICLES: A[] = [
  { section: "Computer Science", title: "Sparse Attention Mechanisms for Low-Resource Language Models", authors: "Ananya Rao, Devashish Kumar", aff: "Indian Institute of Science, Bengaluru", start: 1, end: 14, reviewers: ["Dr Vinod Sharma", "Dr. Ushadevi"], abstract: "We present a sparse attention scheme that reduces inference cost for morphologically rich, low-resource languages without measurable loss in downstream accuracy.", figCap: "Attention sparsity pattern learned across sequence positions.", paras: ["Transformer models are the default for natural language processing, yet quadratic attention cost is a barrier in constrained settings.", "We introduce a learned sparsity pattern allocating attention adaptively, pruning low-signal interactions before the softmax.", "Across four Indian-language benchmarks the approach preserves dense-model accuracy within 0.4 points while cutting latency by 41%.", "The method generalises to speech and vision transformers with minimal modification."] },
  { section: "Computer Science", title: "Federated Learning under Intermittent Connectivity", authors: "Karthik Nair", aff: "IIIT Hyderabad", start: 15, end: 26, reviewers: ["Dr Vinod Sharma", "Prof. S. Y. Surendra Kumar"], abstract: "A federated training protocol tolerant of dropped clients maintains convergence guarantees under the connectivity patterns typical of rural deployments.", figCap: "Convergence under varying client drop rates.", paras: ["Federated learning promises privacy-preserving model training but assumes reliable client availability.", "We model intermittent participation as a stochastic process and derive a weighting scheme that debiases sporadic updates.", "Convergence holds up to a 60% drop rate, with accuracy within two points of the always-available baseline.", "The protocol adds negligible communication overhead."] },
  { section: "Medicine & Public Health", title: "Community Health Worker Networks and Maternal Outcomes in Rural Karnataka", authors: "Priya Menon, S. Nagaraj", aff: "St. John's Research Institute", start: 27, end: 39, reviewers: ["Dr. Ushadevi", "Dr Rajesh M V"], abstract: "A three-year cohort across 62 villages finds structured community health worker networks correlate with a 23% reduction in maternal complications.", figCap: "Complication rates by network density quartile.", paras: ["Maternal outcomes in rural India remain uneven despite sustained public investment.", "We followed 4,180 pregnancies across 62 villages, coding each by network structure and adjusting for facility distance and income.", "Denser networks were associated with a 23% reduction in complications, comparable to infrastructure spending at a fraction of the cost.", "Network-based interventions merit inclusion in maternal health policy."] },
  { section: "Medicine & Public Health", title: "Point-of-Care Diagnostics for Febrile Illness: A Field Evaluation", authors: "R. Deshpande, Meera Iyer", aff: "AIIMS", start: 40, end: 51, reviewers: ["Dr Bishwajit Paul", "Dr. Ushadevi"], abstract: "A low-cost multiplex assay distinguishes common causes of acute febrile illness at the point of care with sensitivity comparable to laboratory testing.", figCap: "Sensitivity and specificity against reference assays.", paras: ["Acute febrile illness is frequently treated empirically for lack of rapid diagnostics.", "We evaluated a multiplex lateral-flow assay against reference PCR across 1,200 patients at primary health centres.", "Sensitivity exceeded 92% for the three most common pathogens, enabling targeted treatment.", "Wider deployment could reduce inappropriate antibiotic use."] },
  { section: "Engineering", title: "Decentralised Greywater Treatment for Peri-Urban Settlements", authors: "Rohan Iyer", aff: "IIT Madras", start: 52, end: 60, reviewers: ["Dr Vinod Sharma", "Dr Kwadwo Boateng"], abstract: "A modular constructed-wetland design treats household greywater to reuse standards at one-fifth the capital cost of centralised systems.", figCap: "Effluent quality over the 18-month monitoring period.", paras: ["Rapid peri-urban growth has outpaced centralised sanitation across South Asia.", "We prototyped a modular constructed wetland for twelve households and monitored effluent for eighteen months.", "The system met reuse standards throughout, at roughly one-fifth the per-household cost of a centralised connection.", "The modular design supports incremental expansion."] },
  { section: "Engineering", title: "Fatigue Life Prediction in Additively Manufactured Titanium", authors: "S. Balakrishnan", aff: "IIT Bombay", start: 61, end: 72, reviewers: ["Dr Bishwajit Paul", "Dr Vinod Sharma"], abstract: "A physics-informed model predicts fatigue life in laser-sintered titanium components from porosity distributions measured by micro-CT.", figCap: "Predicted versus measured cycles to failure.", paras: ["Additive manufacturing enables complex titanium parts but introduces porosity that governs fatigue.", "We couple micro-CT porosity maps with a physics-informed crack-initiation model.", "Predictions fall within a factor of two of measured cycles across three build orientations.", "The approach supports qualification of printed aerospace components."] },
  { section: "Economics", title: "Informal Credit Markets and Small-Enterprise Resilience", authors: "Meera Krishnan, Arjun Pillai", aff: "IFMR, Krea University", start: 73, end: 85, reviewers: ["Dr Kwadwo Boateng", "Dr Rajesh M V"], abstract: "Using transaction data from 9,000 micro-enterprises, informal credit buffers revenue shocks more effectively than formal lines during downturns.", figCap: "Survival curves by dominant credit source.", paras: ["Small enterprises rely on a mix of formal and informal credit whose relative value in a shock is poorly understood.", "Drawing on ledger data from 9,000 micro-enterprises, we tracked drawdowns across a regional downturn.", "Informal credit responded faster and correlated with higher survival, arguing for policy that preserves rather than displaces it.", "The results caution against blanket formalisation mandates."] },
  { section: "Economics", title: "Minimum Support Prices and Cropping Decisions", authors: "V. Subramanian", aff: "Delhi School of Economics", start: 86, end: 97, reviewers: ["Dr Rajesh M V", "Dr Kwadwo Boateng"], abstract: "A district-level panel shows announced support prices shift planting toward covered crops, with implications for water use and dietary diversity.", figCap: "Acreage response to price announcements.", paras: ["Minimum support prices are a central instrument of Indian agricultural policy.", "We assemble a district-level panel linking announcements to subsequent cropping.", "Coverage raises planted acreage of the target crop, sometimes at the expense of water-efficient alternatives.", "Policy design should weigh these downstream effects."] },
  { section: "Materials Science", title: "Room-Temperature Synthesis of Stable Perovskite Thin Films", authors: "Kavya Suresh", aff: "JNCASR, Bengaluru", start: 98, end: 109, reviewers: ["Dr Bishwajit Paul", "Dr. Ushadevi"], abstract: "A solvent-engineering route yields perovskite films with improved ambient stability, retaining 90% of initial efficiency after 1,000 hours.", figCap: "Efficiency retention under ambient exposure.", paras: ["Perovskite photovoltaics promise high efficiency at low cost, but ambient instability has slowed adoption.", "We report a solvent-engineering approach producing uniform films at room temperature.", "Devices retained 90% of initial efficiency after 1,000 hours, removing a significant energy input from fabrication.", "The route is compatible with roll-to-roll processing."] },
  { section: "Materials Science", title: "Graphene-Reinforced Geopolymer Concrete", authors: "N. Fernandes", aff: "IISc, Bengaluru", start: 110, end: 120, reviewers: ["Dr Bishwajit Paul", "Dr Vinod Sharma"], abstract: "Small additions of graphene oxide raise compressive strength and lower permeability in fly-ash geopolymer concrete.", figCap: "Compressive strength versus graphene oxide loading.", paras: ["Geopolymer concrete offers a lower-carbon alternative to Portland cement.", "We disperse graphene oxide at low loadings in a fly-ash geopolymer matrix.", "Compressive strength rose 18% and chloride permeability fell markedly at 0.05% loading.", "The gains persist under accelerated ageing."] },
  { section: "Social Science", title: "Digital Public Infrastructure and Civic Participation", authors: "Nikhil Verma, Lakshmi R.", aff: "National Law School of India University", start: 121, end: 130, reviewers: ["Prof. S. Y. Surendra Kumar", "Dr. Lubna Ambreen"], abstract: "A mixed-methods study of three states finds identity and payment rails raise service uptake but show no consistent effect on broader civic engagement.", figCap: "Service uptake versus civic participation indices.", paras: ["Digital public infrastructure has expanded access to welfare and payments at scale.", "Combining survey data with interviews across three states, we measured uptake and civic participation.", "We find robust gains in service uptake but no consistent spillover into voting or grievance filing.", "Infrastructure alone does not deepen civic life."] },
  { section: "Social Science", title: "Language Policy and Minority Rights: A Comparative View", authors: "A. Thomas", aff: "JNU, New Delhi", start: 131, end: 142, reviewers: ["Dr Rajendran Govender", "Prof. S. Y. Surendra Kumar"], abstract: "Comparing three federations, formal recognition of minority languages correlates with participation but depends on funded implementation.", figCap: "Recognition indices across three federations.", paras: ["Language policy sits at the intersection of identity, rights, and administration.", "We compare constitutional recognition and implementation across three federal systems.", "Recognition tracks participation only where matched by sustained funding for education and services.", "Symbolic recognition without resourcing yields little."] },
];

async function main() {
  for (const name of SECTIONS) {
    await prisma.section.upsert({ where: { slug: slug(name) }, update: {}, create: { name, slug: slug(name) } });
  }
  const issue = await prisma.issue.upsert({
    where: { volume_number: { volume: 1, number: 1 } },
    update: { isCurrent: true },
    create: { volume: 1, number: 1, label: "July 2026", isCurrent: true, publishedAt: new Date() },
  });

  const hash = await bcrypt.hash(DEFAULT_PASSWORD, 10);
  const users: Record<string, string> = {};
  for (const u of STAFF) {
    const rec = await prisma.user.upsert({
      where: { email: u.email },
      update: { role: u.role, approved: true, passwordHash: hash, affiliation: u.affiliation },
      create: { email: u.email, name: u.name, role: u.role, approved: true, passwordHash: hash, affiliation: u.affiliation },
    });
    users[u.name] = rec.id;
  }
  const chiefId = users["Prof. Vidyadhar Reddy Aileni"];
  const submitterId = users["IJRI Admin"];

  let created = 0;
  for (const a of ARTICLES) {
    const section = await prisma.section.findUnique({ where: { slug: slug(a.section) } });
    if (!section) continue;
    if (await prisma.article.findFirst({ where: { title: a.title } })) continue;
    const article = await prisma.article.create({
      data: {
        title: a.title, abstract: a.abstract, bodyHtml: body(a.paras, a.figCap),
        authorNames: a.authors, affiliation: a.aff, status: "PUBLISHED",
        sectionId: section.id, issueId: issue.id, startPage: a.start, endPage: a.end,
        submittedById: submitterId, chiefEditorId: chiefId, decidedAt: new Date(), publishedAt: new Date(),
      },
    });
    for (const rn of a.reviewers) {
      const eid = users[rn];
      if (eid) await prisma.review.create({ data: { articleId: article.id, editorId: eid, recommendation: "ACCEPT" } });
    }
    created++;
  }
  console.log(`Seed complete: ${SECTIONS.length} sections, ${STAFF.length} staff/editors, ${created} new articles. Password: ${DEFAULT_PASSWORD}`);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
IJRI_EOF

# ---------------------------------------------------------------- board page: board vs assistance separated
cat > src/app/editorial-board/page.tsx << 'IJRI_EOF'
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type Member = { name: string; title: string; affiliation: string; bio?: string; photo?: string };

const BOARD: Member[] = [
  { name: "Prof. Vidyadhar Reddy Aileni", title: "Editor-in-Chief · Former Dean, Faculty of Management", affiliation: "Osmania University; former Director, CMS, NALSAR University of Law, Hyderabad" },
  { name: "Dr Rajendran Govender", title: "Commissioner, Cultural, Religious and Linguistic Rights Commission", affiliation: "Republic of South Africa; Social Anthropologist; Ford and IBSA Fellow" },
  { name: "Dr. Ushadevi", title: "Professor and Chairperson, Department of Physics", affiliation: "Bangalore University" },
  { name: "Prof. S. Y. Surendra Kumar", title: "Professor and Chairperson, Department of Political Science", affiliation: "Bangalore University, Bengaluru", bio: "Professor of Political Science with 20 years of teaching experience. He earned his M.Phil. and Ph.D. in South Asian Studies at Jawaharlal Nehru University and has authored four books, over 25 book chapters, and more than 40 research articles. His research areas are public policy, South Asian security, and Indian foreign policy toward the United States and China." },
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
  { name: "Praveen Kumar H", title: "Data Science Senior Lead (VP)", affiliation: "Wells Fargo" },
  { name: "Amaresh Gadagi", title: "Manager, Customer Service", affiliation: "LKQ India Private Limited, Bangalore" },
  { name: "Shaan", title: "Editorial Assistance", affiliation: "—" },
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
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 8px" }}>
        The board comprises senior academics and practitioners who set editorial policy and conduct double-blind peer review. All correspondence is handled through the journal&rsquo;s editorial office.
      </p>
      {BOARD.map((m) => <BoardCard key={m.name} m={m} />)}

      <section style={{ marginTop: 48, background: T.g100, border: `1px solid ${T.rule}`, padding: "8px 24px 24px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink, marginTop: 20 }}>
          <IconUsers size={20} /><Eyebrow>Editorial Assistance</Eyebrow>
        </div>
        <p style={{ fontFamily: T.serif, fontSize: 15.5, lineHeight: 1.55, color: T.muted, margin: "10px 0 4px" }}>
          The following provide editorial, technical, and operational support to the board.
        </p>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "0 26px" }} className="cardgrid">
          {ASSIST.map((m) => (
            <div key={m.name} style={{ padding: "16px 0", borderTop: `1px solid ${T.g300}` }}>
              <h3 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 18, margin: "0 0 3px" }}>{m.name}</h3>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.ink }}>{m.title}</div>
              <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 1 }}>{m.affiliation}</div>
            </div>
          ))}
        </div>
      </section>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Data layer written. Now run:"
echo "  npx prisma db push"
echo "  npm run seed"
