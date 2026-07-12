import { PrismaClient } from "@prisma/client";
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

const body = (paras: string[], figCap: string) =>
  `<p>${paras[0]}</p>${FIG(1, figCap)}<h2>Methods</h2><p>${paras[1]}</p><h2>Results and discussion</h2><p>${paras[2]}</p><blockquote>These findings suggest a path that is both practical and reproducible in resource-constrained settings.</blockquote>`;

const ARTICLES = [
  { section: "Computer Science", title: "Sparse Attention Mechanisms for Low-Resource Language Models", authors: "Ananya Rao, Devashish Kumar", aff: "Indian Institute of Science, Bengaluru", start: 1, end: 14, reviewers: ["Dr. Rohan Iyer", "Dr. Priya Menon"], abstract: "We present a sparse attention scheme that reduces inference cost for morphologically rich, low-resource languages without measurable loss in downstream accuracy.", figCap: "Attention sparsity pattern learned across sequence positions.", paras: ["Transformer models have become the default architecture for natural language processing, yet their quadratic attention cost remains a barrier in resource-constrained settings.", "We introduce a learned sparsity pattern that allocates attention budget adaptively across a sequence, pruning low-signal interactions before the softmax.", "Across four Indian-language benchmarks the approach preserves dense-model accuracy within 0.4 points while cutting latency by 41%."] },
  { section: "Medicine & Public Health", title: "Community Health Worker Networks and Maternal Outcomes in Rural Karnataka", authors: "Priya Menon, S. Nagaraj", aff: "St. John's Research Institute", start: 15, end: 27, reviewers: ["Dr. Ananya Rao", "Dr. Rohan Iyer"], abstract: "A three-year cohort study across 62 villages finds that structured community health worker networks correlate with a 23% reduction in maternal complication rates.", figCap: "Complication rates by network density quartile.", paras: ["Maternal health outcomes in rural India remain uneven despite sustained public investment.", "We followed 4,180 pregnancies across 62 villages over three years, coding each village by network structure and adjusting for facility distance and income.", "Denser networks were associated with a 23% reduction in complications, comparable to infrastructure spending at a fraction of the cost."] },
  { section: "Engineering", title: "Decentralised Greywater Treatment for Peri-Urban Settlements", authors: "Rohan Iyer", aff: "IIT Madras", start: 28, end: 36, reviewers: ["Dr. Ananya Rao", "Dr. Meera Krishnan"], abstract: "A modular constructed-wetland design treats household greywater to reuse standards at one-fifth the capital cost of centralised systems.", figCap: "Effluent quality over the 18-month monitoring period.", paras: ["Rapid peri-urban growth has outpaced centralised sanitation across much of South Asia.", "We prototyped a modular constructed wetland for a cluster of twelve households and monitored effluent quality for eighteen months.", "The system met reuse standards throughout, at roughly one-fifth the per-household cost of a centralised connection."] },
  { section: "Economics", title: "Informal Credit Markets and Small-Enterprise Resilience", authors: "Meera Krishnan, Arjun Pillai", aff: "IFMR, Krea University", start: 37, end: 49, reviewers: ["Dr. Ananya Rao", "Dr. Priya Menon"], abstract: "Using transaction data from 9,000 micro-enterprises, we find that access to informal credit buffers revenue shocks more effectively than formal lines during downturns.", figCap: "Survival curves by dominant credit source.", paras: ["Small enterprises in emerging markets rely on a mix of formal and informal credit whose relative value in a shock is poorly understood.", "Drawing on ledger data from 9,000 micro-enterprises, we tracked drawdowns across a regional demand downturn.", "Informal credit responded faster and correlated with higher survival, arguing for policy that preserves rather than displaces it."] },
  { section: "Materials Science", title: "Room-Temperature Synthesis of Stable Perovskite Thin Films", authors: "Kavya Suresh", aff: "JNCASR, Bengaluru", start: 50, end: 61, reviewers: ["Dr. Rohan Iyer", "Dr. Priya Menon"], abstract: "A solvent-engineering route yields perovskite films with improved ambient stability, retaining 90% of initial efficiency after 1,000 hours.", figCap: "Efficiency retention under ambient exposure.", paras: ["Perovskite photovoltaics promise high efficiency at low cost, but ambient instability has slowed adoption.", "We report a solvent-engineering approach producing uniform films at room temperature.", "Devices retained 90% of initial efficiency after 1,000 hours, removing a significant energy input from fabrication."] },
  { section: "Social Science", title: "Digital Public Infrastructure and Civic Participation", authors: "Nikhil Verma, Lakshmi R.", aff: "National Law School of India University", start: 62, end: 71, reviewers: ["Dr. Ananya Rao", "Dr. Meera Krishnan"], abstract: "A mixed-methods study of three states finds that identity and payment rails raise service uptake but show no consistent effect on broader civic engagement.", figCap: "Service uptake vs civic participation indices.", paras: ["Digital public infrastructure has expanded access to welfare and payments at unprecedented scale.", "Combining survey data with interviews across three states, we measured uptake and civic participation.", "We find robust gains in service uptake but no consistent spillover into voting or grievance filing."] },
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
  const staff = [
    { email: "admin@ijrein.org", name: "IJRI Admin", role: "ADMIN" as const },
    { email: "snagaraj@iisc.ac.in", name: "Prof. S. Nagaraj", role: "CHIEF_EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "arao@iisc.ac.in", name: "Dr. Ananya Rao", role: "EDITOR" as const, affiliation: "Indian Institute of Science" },
    { email: "riyer@iitm.ac.in", name: "Dr. Rohan Iyer", role: "EDITOR" as const, affiliation: "IIT Madras" },
    { email: "pmenon@sjri.res.in", name: "Dr. Priya Menon", role: "EDITOR" as const, affiliation: "St. John's Research Institute" },
    { email: "mkrishnan@krea.edu.in", name: "Dr. Meera Krishnan", role: "EDITOR" as const, affiliation: "IFMR, Krea University" },
  ];
  const users: Record<string, string> = {};
  for (const u of staff) {
    const rec = await prisma.user.upsert({ where: { email: u.email }, update: { role: u.role, passwordHash: hash }, create: { ...u, passwordHash: hash } });
    users[u.name] = rec.id;
  }
  const chiefId = users["Prof. S. Nagaraj"];
  const submitterId = users["IJRI Admin"];

  for (const a of ARTICLES) {
    const section = await prisma.section.findUnique({ where: { slug: slug(a.section) } });
    if (!section) continue;
    const existing = await prisma.article.findFirst({ where: { title: a.title } });
    if (existing) continue;
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
  }
  console.log(`Seed complete: ${SECTIONS.length} sections, current issue, ${staff.length} staff, ${ARTICLES.length} articles. Staff password: ${DEFAULT_PASSWORD}`);
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
