#!/usr/bin/env bash
# ==========================================================================
# IJRI — frontend port, stage 1: the reader experience on real data.
#   - adds rich-HTML article fields
#   - seeds 6 published sample articles (with figures) into the current issue
#   - ports home, article (server-side paywall), and archives pages
# Run in the repo:  bash build-reader.sh
# Then:  npm install sanitize-html && npm install -D @types/sanitize-html
#        npx prisma migrate dev --name article_html   (or: npx prisma db push)
#        npm run seed
#        npm run build   # verify, then commit & push
# ==========================================================================
set -euo pipefail
echo "Building reader (stage 1)..."

mkdir -p src/lib src/app "src/app/articles/[id]" src/app/archives \
         "src/app/api/articles/[id]" src/app/api/submissions

# ---------------------------------------------------------------- schema (adds bodyHtml/coverImage)
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
  affiliation   String?
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

# ---------------------------------------------------------------- seed (sections, issue, staff, sample articles)
cat > prisma/seed.ts << 'IJRI_EOF'
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
IJRI_EOF

# ---------------------------------------------------------------- ui tokens + primitives (server-safe)
cat > src/lib/ui.tsx << 'IJRI_EOF'
import React from "react";

export const T = {
  serif: "'Iowan Old Style','Charter','Palatino Linotype',Georgia,'Times New Roman',serif",
  sans: "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif",
  ink: "#111111", paper: "#ffffff", muted: "#6b6b6b", faint: "#f6f6f6", rule: "#e4e4e4",
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

# ---------------------------------------------------------------- sanitize
cat > src/lib/sanitize.ts << 'IJRI_EOF'
import sanitizeHtml from "sanitize-html";

// Sanitises stored article HTML before rendering. Rich enough for scholarly
// articles (headings, figures, tables, emphasis) but strips anything scriptable.
export function sanitize(dirty: string): string {
  return sanitizeHtml(dirty, {
    allowedTags: ["p", "h2", "h3", "h4", "ul", "ol", "li", "strong", "em", "b", "i", "u", "blockquote", "figure", "figcaption", "img", "a", "br", "hr", "sup", "sub", "table", "thead", "tbody", "tr", "td", "th", "code", "pre", "div", "span"],
    allowedAttributes: { a: ["href", "name", "target", "rel"], img: ["src", "alt", "width", "height"], "*": ["style"] },
    allowedSchemes: ["https", "data"],
  });
}
IJRI_EOF

# ---------------------------------------------------------------- layout (chrome + global style)
cat > src/app/layout.tsx << 'IJRI_EOF'
import Link from "next/link";
import { T } from "@/lib/ui";

export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary, double-blind peer-reviewed research journal.",
};

const CURRENT = "Volume 1, Issue 1 · July 2026";

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
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} }
        `}</style>

        <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
          <div style={{ borderBottom: `1px solid ${T.rule}` }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
              <span>e-ISSN: applied for</span><span>Double-blind peer-reviewed</span>
            </div>
          </div>
          <div style={{ maxWidth: 1120, margin: "0 auto", padding: "22px 20px 12px", textAlign: "center" }}>
            <Link href="/" style={{ fontFamily: T.serif, fontWeight: 500, lineHeight: 1.02, color: T.ink, fontSize: "clamp(24px,5vw,44px)", display: "inline-block" }}>
              International Journal of<br />Research and Innovation
            </Link>
          </div>
          <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
              Current issue · {CURRENT}
            </div>
          </div>
          <nav className="nav" style={{ background: T.faint }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
              {[["/", "Home"], ["/archives", "Archives"]].map(([href, label]) => (
                <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
              ))}
            </div>
          </nav>
        </header>

        {children}

        <footer style={{ borderTop: `1px solid ${T.ink}`, background: T.faint, marginTop: 40 }}>
          <div style={{ maxWidth: 1120, margin: "0 auto", padding: "26px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
            International Journal of Research and Innovation · ijrein.org · e-ISSN applied for
          </div>
        </footer>
      </body>
    </html>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- home
cat > src/app/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Home() {
  const articles = await prisma.article.findMany({
    where: { status: "PUBLISHED" },
    include: { section: true },
    orderBy: { startPage: "asc" },
  });

  if (articles.length === 0) {
    return <main style={{ maxWidth: 680, margin: "60px auto", padding: "0 20px", fontFamily: T.serif }}><p>No articles have been published yet.</p></main>;
  }

  const [lead, ...rest] = articles;

  return (
    <main style={{ maxWidth: 1120, margin: "0 auto", padding: "32px 20px 40px" }}>
      <section className="leadgrid" style={{ display: "grid", gridTemplateColumns: "minmax(0,2fr) 1px minmax(0,1fr)", gap: 32, alignItems: "start", paddingBottom: 32, borderBottom: `1px solid ${T.ink}` }}>
        <Link href={`/articles/${lead.id}`}>
          <Eyebrow inverse>From the current issue</Eyebrow>
          <h1 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, lineHeight: 1.08, fontSize: "clamp(27px,4.4vw,44px)", margin: "14px 0" }}>{lead.title}</h1>
          <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.5, color: "#2a2a2a", margin: "0 0 12px" }}>{lead.abstract}</p>
          <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>{lead.authorNames} · {lead.affiliation}</div>
        </Link>
        <div style={{ background: T.rule, width: 1, height: "100%" }} />
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <Eyebrow>Also in this issue</Eyebrow>
          {rest.slice(0, 3).map((a, i) => (
            <Link key={a.id} href={`/articles/${a.id}`} style={{ paddingTop: i === 0 ? 4 : 16, borderTop: i === 0 ? "none" : `1px solid ${T.rule}` }}>
              <Eyebrow>{a.section.name}</Eyebrow>
              <h3 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 18, lineHeight: 1.2, margin: "6px 0 4px" }}>{a.title}</h3>
              <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.authorNames}</div>
            </Link>
          ))}
        </div>
      </section>

      <section className="cardgrid" style={{ display: "grid", gridTemplateColumns: "repeat(3,minmax(0,1fr))", gap: "32px 30px", marginTop: 32 }}>
        {rest.slice(3).map((a) => (
          <Link key={a.id} href={`/articles/${a.id}`}>
            <Eyebrow>{a.section.name}</Eyebrow>
            <h3 className="cardtitle" style={{ fontFamily: T.serif, fontWeight: 600, fontSize: 21, lineHeight: 1.2, margin: "8px 0 6px" }}>{a.title}</h3>
            <p style={{ fontFamily: T.serif, fontSize: 15, lineHeight: 1.5, color: "#333", margin: "0 0 8px" }}>{a.abstract}</p>
            <div style={{ fontFamily: T.sans, fontSize: 12, color: T.muted }}>{a.authorNames} · pp. {pages(a)}</div>
          </Link>
        ))}
      </section>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- article (server-side paywall)
cat > "src/app/articles/[id]/page.tsx" << 'IJRI_EOF'
import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";
import { sanitize } from "@/lib/sanitize";
import { T, Eyebrow, Chip, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function ArticlePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    include: {
      section: true, issue: true,
      reviews: { include: { editor: { select: { name: true } } } },
      chiefEditor: { select: { name: true } },
    },
  });
  if (!article) notFound();

  const user = await getCurrentUser();
  const unlocked = await canReadArticle(user, article);

  return (
    <main style={{ maxWidth: 680, margin: "0 auto", padding: "32px 20px 40px" }}>
      <Link href="/" style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>← Back to issue</Link>
      <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted, margin: "18px 0 12px", lineHeight: 1.5 }}>
        International Journal of Research and Innovation<br />
        Vol {article.issue?.volume}, Issue {article.issue?.number} ({article.issue?.label}), pp. {pages(article)}
      </div>
      <Eyebrow inverse>{article.section.name}</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, lineHeight: 1.1, fontSize: "clamp(28px,5vw,42px)", margin: "16px 0 18px" }}>{article.title}</h1>
      <div style={{ fontFamily: T.sans, fontSize: 14, borderTop: `1px solid ${T.rule}`, borderBottom: `1px solid ${T.rule}`, padding: "12px 0" }}>
        <strong style={{ fontWeight: 600 }}>{article.authorNames}</strong><span style={{ color: T.muted }}> · {article.affiliation}</span>
      </div>

      <div style={{ background: T.faint, borderLeft: `3px solid ${T.ink}`, padding: "16px 20px", margin: "26px 0" }}>
        <Eyebrow>Abstract</Eyebrow>
        <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.55, color: "#222", margin: "8px 0 0" }}>{article.abstract}</p>
      </div>

      {unlocked ? (
        <div className="body" dangerouslySetInnerHTML={{ __html: sanitize(article.bodyHtml ?? "") }} />
      ) : (
        <section style={{ border: `1px solid ${T.ink}`, padding: "22px 20px", margin: "10px 0 20px", background: T.faint }}>
          <Eyebrow inverse>Subscribers only</Eyebrow>
          <h3 style={{ fontFamily: T.serif, fontSize: 22, margin: "12px 0 6px" }}>Continue reading the full article</h3>
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, lineHeight: 1.6, margin: 0 }}>
            The abstract is free. Full text and PDF download require a subscription. {user ? "" : "Sign in or subscribe to continue."}
          </p>
        </section>
      )}

      <section style={{ marginTop: 30, border: `1px solid ${T.ink}`, padding: "18px 20px" }}>
        <Eyebrow>Peer review</Eyebrow>
        <p style={{ fontFamily: T.sans, fontSize: 13, margin: "10px 0 8px", lineHeight: 1.6 }}>Reviewed under double-blind evaluation by {article.reviews.length} members of the editorial board:</p>
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {article.reviews.map((r) => <Chip key={r.id}>{r.editor.name}</Chip>)}
        </div>
        {article.chiefEditor && <div style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, borderTop: `1px solid ${T.rule}`, marginTop: 12, paddingTop: 10 }}>Accepted and published by <strong style={{ color: T.ink }}>{article.chiefEditor.name}</strong>, Editor-in-Chief.</div>}
      </section>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- archives
cat > src/app/archives/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow, pages } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Archives() {
  const issues = await prisma.issue.findMany({
    orderBy: [{ volume: "desc" }, { number: "desc" }],
    include: {
      articles: { where: { status: "PUBLISHED" }, include: { section: true }, orderBy: { startPage: "asc" } },
    },
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Archives</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 24px" }}>Archives</h1>
      {issues.map((iss) => (
        <div key={iss.id} style={{ border: `1px solid ${T.ink}`, marginBottom: 24 }}>
          <div style={{ background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.08em", textTransform: "uppercase", fontWeight: 600, padding: "10px 16px" }}>
            IJRI · Volume {iss.volume}, Issue {iss.number} · {iss.label}
          </div>
          {iss.articles.map((a, i) => (
            <div key={a.id} style={{ display: "grid", gridTemplateColumns: "30px 1fr auto", gap: 12, padding: "14px 16px", borderTop: i === 0 ? "none" : `1px solid ${T.rule}` }}>
              <div style={{ fontFamily: T.serif, fontSize: 16, color: T.muted }}>{i + 1}.</div>
              <div>
                <Link href={`/articles/${a.id}`}><span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.3 }}>{a.title}</span></Link>
                <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 3 }}>{a.authorNames} · {a.section.name} · pp. {pages(a)}</div>
              </div>
              <Link href={`/articles/${a.id}`} style={{ fontFamily: T.sans, fontSize: 11.5, textDecoration: "underline", textUnderlineOffset: 2, whiteSpace: "nowrap" }}>Read</Link>
            </div>
          ))}
        </div>
      ))}
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- update article API to return bodyHtml
cat > "src/app/api/articles/[id]/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser } from "@/lib/auth";
import { canReadArticle } from "@/lib/entitlements";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const article = await prisma.article.findFirst({
    where: { id, status: "PUBLISHED" },
    include: {
      section: true, issue: true,
      reviews: { include: { editor: { select: { name: true } } } },
      chiefEditor: { select: { name: true } },
    },
  });
  if (!article) return Response.json({ error: "Not found" }, { status: 404 });

  const user = await getCurrentUser(req);
  const unlocked = await canReadArticle(user, article);

  const payload = {
    id: article.id, title: article.title, abstract: article.abstract,
    authorNames: article.authorNames, affiliation: article.affiliation,
    section: article.section.name, volume: article.issue?.volume, issue: article.issue?.number,
    pages: article.startPage && article.endPage ? `${article.startPage}-${article.endPage}` : null,
    doi: article.doi, reviewers: article.reviews.map((r) => r.editor.name),
    chiefEditor: article.chiefEditor?.name ?? null, locked: !unlocked,
  };
  if (!unlocked) return Response.json(payload);
  return Response.json({ ...payload, bodyHtml: article.bodyHtml });
}
IJRI_EOF

# ---------------------------------------------------------------- update submissions POST to accept bodyHtml
cat > src/app/api/submissions/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getCurrentUser, isStaff, unauthorized } from "@/lib/auth";

export async function POST(req: Request) {
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  const b = await req.json();
  const { title, abstract, bodyHtml, authorNames, affiliation, sectionId } = b ?? {};
  if (!title || !abstract || !bodyHtml || !sectionId)
    return Response.json({ error: "Missing required fields" }, { status: 400 });

  const article = await prisma.article.create({
    data: {
      title, abstract, bodyHtml,
      authorNames: authorNames ?? user.name, affiliation, sectionId,
      status: "SUBMITTED", submittedById: user.id,
    },
    select: { id: true, status: true },
  });
  return Response.json(article, { status: 201 });
}

export async function GET(req: Request) {
  const user = await getCurrentUser(req);
  if (!user) return unauthorized();
  if (!isStaff(user.role)) return Response.json({ error: "Not permitted" }, { status: 403 });
  const queue = await prisma.article.findMany({
    where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } },
    include: { section: { select: { name: true } }, reviews: { include: { editor: { select: { name: true } } } } },
    orderBy: { createdAt: "asc" },
  });
  return Response.json(queue);
}
IJRI_EOF

echo ""
echo "Reader stage 1 written. Now run:"
echo "  npm install sanitize-html && npm install -D @types/sanitize-html"
echo "  npx prisma migrate dev --name article_html   # or: npx prisma db push"
echo "  npm run seed"
echo "  npm run build"
echo "  git add . && git commit -m 'Frontend stage 1: reader + sample articles' && git push origin main"
