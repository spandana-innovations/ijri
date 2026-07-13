#!/usr/bin/env bash
# ==========================================================================
# IJRI — Profiles v2:
#   - photo upload auto-converted to B&W high-contrast in the browser (house look)
#   - monochrome preset avatars (initials, cap, ball, wizard, book, flask)
#   - LinkedIn + X + Google Scholar + website; ORCID and photo-URL removed
#   - bio strictly plain text
#   - shared <Avatar> used across the app
#   - public author profile at /people/[id] with their published articles
# Run in repo:  bash build-profile2.sh  ->  npx prisma db push  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Profiles v2..."

BASE="src/app"
[ -d "src/app/(backend)" ] && BASE="src/app/(backend)"
mkdir -p prisma src/components src/app/people/"[id]" src/app/api/account/profile "$BASE/dashboard/profile"

# ---------------------------------------------------------------- schema (profile fields v2)
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
  REVISION_REQUESTED
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

enum EventType {
  VIEW
  DOWNLOAD
  SHARE
}

model User {
  id            String   @id @default(cuid())
  email         String   @unique
  name          String
  role          Role     @default(AUTHOR)
  approved      Boolean  @default(false)
  affiliation   String?
  designation   String?
  website       String?
  linkedin      String?
  twitter       String?
  scholar       String?
  bio           String?  @db.Text
  image         String?  @db.Text
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
  id                    String        @id @default(cuid())
  title                 String
  abstract              String
  bodyHtml              String?       @db.Text
  coverImage            String?
  authorNames           String
  affiliation           String?
  status                ArticleStatus @default(SUBMITTED)
  editorFeedback        String?       @db.Text
  revisionCount         Int           @default(0)
  similarityScore       Int?
  similarityMatchesJson String?       @db.Text
  section               Section       @relation(fields: [sectionId], references: [id])
  sectionId             String
  issue                 Issue?        @relation(fields: [issueId], references: [id])
  issueId               String?
  startPage             Int?
  endPage               Int?
  doi                   String?       @unique
  pdfKey                String?
  submittedBy           User          @relation("SubmittedBy", fields: [submittedById], references: [id])
  submittedById         String
  chiefEditor           User?         @relation("DecidedBy", fields: [chiefEditorId], references: [id])
  chiefEditorId         String?
  decidedAt             DateTime?
  assignments           ReviewAssignment[]
  reviews               Review[]
  purchases             ArticlePurchase[]
  events                ArticleEvent[]
  revisions             ArticleRevision[]
  createdAt             DateTime      @default(now())
  publishedAt           DateTime?

  @@index([status])
  @@index([issueId])
}

model ReviewAssignment {
  id        String   @id @default(cuid())
  article   Article  @relation(fields: [articleId], references: [id])
  articleId String
  editorId  String
  createdAt DateTime @default(now())

  @@unique([articleId, editorId])
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

model ArticleEvent {
  id        String    @id @default(cuid())
  article   Article   @relation(fields: [articleId], references: [id])
  articleId String
  type      EventType
  device    String?
  createdAt DateTime  @default(now())

  @@index([articleId, type])
  @@index([type, createdAt])
}

model ArticleRevision {
  id           String   @id @default(cuid())
  article      Article  @relation(fields: [articleId], references: [id])
  articleId    String
  title        String
  abstract     String
  bodyHtml     String?  @db.Text
  editedByName String
  createdAt    DateTime @default(now())

  @@index([articleId, createdAt])
}
IJRI_EOF

# ---------------------------------------------------------------- shared Avatar (pure component)
cat > src/components/Avatar.tsx << 'IJRI_EOF'
import { T } from "@/lib/ui";

// Monochrome preset avatars — simple inline SVGs, no colour.
const PRESETS: Record<string, React.ReactNode> = {
  cap: (<g><path d="M50 22 90 40 50 58 10 40Z" fill="currentColor" /><path d="M74 48v16c0 8-11 13-24 13S26 72 26 64V48l24 11 24-11Z" fill="currentColor" opacity="0.75" /><rect x="88" y="40" width="3" height="22" fill="currentColor" /></g>),
  ball: (<g><circle cx="50" cy="50" r="30" fill="none" stroke="currentColor" strokeWidth="5" /><path d="M50 20v60M20 50h60M28 28l44 44M72 28 28 72" stroke="currentColor" strokeWidth="3" /></g>),
  wizard: (<g><path d="M50 14 78 74H22Z" fill="currentColor" /><circle cx="42" cy="40" r="3" fill={T.paper} /><circle cx="58" cy="56" r="2.5" fill={T.paper} /><rect x="16" y="74" width="68" height="8" rx="4" fill="currentColor" /></g>),
  book: (<g><path d="M50 26c-10-7-24-7-34-3v46c10-4 24-4 34 3 10-7 24-7 34-3V23c-10-4-24-4-34 3Z" fill="none" stroke="currentColor" strokeWidth="5" strokeLinejoin="round" /><path d="M50 26v46" stroke="currentColor" strokeWidth="4" /></g>),
  flask: (<g><path d="M42 20h16M46 20v22L28 74c-3 5 0 10 6 10h32c6 0 9-5 6-10L54 42V20" fill="none" stroke="currentColor" strokeWidth="5" strokeLinejoin="round" /><path d="M36 62h28" stroke="currentColor" strokeWidth="4" /></g>),
};

function initials(name: string) {
  return (name || "?").split(/\s+/).filter(Boolean).map((w) => w[0]).slice(0, 2).join("").toUpperCase();
}

export default function Avatar({ image, name, size = 72 }: { image?: string | null; name: string; size?: number }) {
  const box: React.CSSProperties = { width: size, height: size, flex: `0 0 ${size}px`, border: `1px solid ${T.rule}`, background: T.g100, display: "flex", alignItems: "center", justifyContent: "center", overflow: "hidden" };

  if (image && image.startsWith("data:")) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={image} alt={name} style={{ ...box, objectFit: "cover", filter: "grayscale(1) contrast(1.15)" }} />;
  }
  const preset = image && image.startsWith("preset:") ? image.slice(7) : "";
  if (preset && PRESETS[preset]) {
    return (
      <div style={{ ...box, color: T.ink, background: T.paper }}>
        <svg viewBox="0 0 100 100" width={size * 0.7} height={size * 0.7} xmlns="http://www.w3.org/2000/svg">{PRESETS[preset]}</svg>
      </div>
    );
  }
  return <div style={{ ...box, background: T.ink, color: T.paper, fontFamily: T.serif, fontSize: size * 0.38 }}>{initials(name)}</div>;
}

export const AVATAR_PRESETS = ["initials", "cap", "ball", "wizard", "book", "flask"] as const;
IJRI_EOF

# ---------------------------------------------------------------- profile API (v2 fields, strip bio, cap image)
cat > src/app/api/account/profile/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized } from "@/lib/auth";

const MAX_IMAGE = 350_000; // ~350 KB data URL cap

export async function PATCH(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const b = await req.json().catch(() => null);
  const data: Record<string, string> = {};
  for (const f of ["name", "affiliation", "designation", "website", "linkedin", "twitter", "scholar"]) {
    if (typeof b?.[f] === "string") data[f] = b[f].trim();
  }
  if (typeof b?.bio === "string") data.bio = b.bio.replace(/<[^>]+>/g, "").trim(); // strictly plain text
  if (typeof b?.image === "string") {
    const img = b.image.trim();
    if (img === "" || img.startsWith("preset:")) data.image = img;
    else if (img.startsWith("data:image/") && img.length <= MAX_IMAGE) data.image = img;
    else return Response.json({ error: "Image is invalid or too large" }, { status: 400 });
  }
  if (typeof b?.email === "string" && b.email.trim()) {
    const email = b.email.trim().toLowerCase();
    const existing = await prisma.user.findUnique({ where: { email }, select: { id: true } });
    if (existing && existing.id !== acc.id) return Response.json({ error: "That email is already in use" }, { status: 409 });
    data.email = email;
  }
  if (data.name === "") return Response.json({ error: "Name is required" }, { status: 400 });

  await prisma.user.update({ where: { id: acc.id }, data });
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- profile page (server)
cat > "$BASE/dashboard/profile/page.tsx" << 'IJRI_EOF'
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import ProfileForm from "./ProfileForm";

export const dynamic = "force-dynamic";

export default async function ProfilePage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const u = await prisma.user.findUnique({
    where: { id: acc.id },
    select: { name: true, email: true, affiliation: true, designation: true, website: true, linkedin: true, twitter: true, scholar: true, bio: true, image: true, role: true },
  });
  if (!u) redirect("/login");
  return <ProfileForm user={u} />;
}
IJRI_EOF

# ---------------------------------------------------------------- profile form (client, B&W processing + presets)
cat > "$BASE/dashboard/profile/ProfileForm.tsx" << 'IJRI_EOF'
"use client";
import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";
import Avatar, { AVATAR_PRESETS } from "@/components/Avatar";

type U = { name: string; email: string; affiliation: string | null; designation: string | null; website: string | null; linkedin: string | null; twitter: string | null; scholar: string | null; bio: string | null; image: string | null; role: string };

async function toBlackAndWhite(file: File): Promise<string> {
  const url = URL.createObjectURL(file);
  try {
    const img = await new Promise<HTMLImageElement>((res, rej) => { const i = new Image(); i.onload = () => res(i); i.onerror = rej; i.src = url; });
    const size = 400;
    const canvas = document.createElement("canvas"); canvas.width = size; canvas.height = size;
    const ctx = canvas.getContext("2d")!;
    const scale = Math.max(size / img.width, size / img.height);
    const w = img.width * scale, h = img.height * scale;
    ctx.drawImage(img, (size - w) / 2, (size - h) / 2, w, h);
    const data = ctx.getImageData(0, 0, size, size); const d = data.data;
    const contrast = 1.6, intercept = 128 * (1 - contrast);
    for (let i = 0; i < d.length; i += 4) {
      let g = 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2];
      g = Math.max(0, Math.min(255, g * contrast + intercept));
      d[i] = d[i + 1] = d[i + 2] = g;
    }
    ctx.putImageData(data, 0, 0);
    return canvas.toDataURL("image/jpeg", 0.72);
  } finally { URL.revokeObjectURL(url); }
}

export default function ProfileForm({ user }: { user: U }) {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [image, setImage] = useState(user.image ?? "");
  const [f, setF] = useState({
    name: user.name ?? "", email: user.email ?? "", affiliation: user.affiliation ?? "", designation: user.designation ?? "",
    website: user.website ?? "", linkedin: user.linkedin ?? "", twitter: user.twitter ?? "", scholar: user.scholar ?? "", bio: user.bio ?? "",
  });
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });

  async function onFile(file?: File) {
    if (!file) return;
    setMsg("Processing photo…");
    try { setImage(await toBlackAndWhite(file)); setMsg(""); }
    catch { setMsg("Could not process that image."); }
  }

  async function save() {
    setBusy(true); setMsg("");
    const r = await fetch("/api/account/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ...f, image }) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save"); return; }
    setMsg("Saved."); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>My profile</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 18px" }}>My profile</h1>

      {/* avatar + picker */}
      <div style={{ display: "flex", gap: 18, alignItems: "flex-start", marginBottom: 24, flexWrap: "wrap" }}>
        <Avatar image={image} name={f.name} size={92} />
        <div style={{ flex: 1, minWidth: 240 }}>
          <button onClick={() => fileRef.current?.click()} style={{ padding: "9px 16px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", cursor: "pointer" }}>Upload photo</button>
          <input ref={fileRef} type="file" accept="image/*" style={{ display: "none" }} onChange={(e) => onFile(e.target.files?.[0])} />
          <p style={{ fontFamily: T.sans, fontSize: 12, color: T.muted, margin: "8px 0 10px" }}>Photos are converted to the journal&rsquo;s black-and-white house style. Prefer a symbol? Pick one:</p>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            {AVATAR_PRESETS.map((p) => {
              const val = p === "initials" ? "" : `preset:${p}`;
              const active = image === val;
              return (
                <button key={p} onClick={() => setImage(val)} title={p} style={{ border: active ? `2px solid ${T.ink}` : `1px solid ${T.rule}`, padding: 2, background: T.paper, cursor: "pointer" }}>
                  <Avatar image={val} name={f.name} size={40} />
                </button>
              );
            })}
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gap: 14, maxWidth: 640 }}>
        <div><span style={label}>Full name</span><input style={input} value={f.name} onChange={set("name")} /></div>
        <div><span style={label}>Email (your sign-in)</span><input style={input} type="email" value={f.email} onChange={set("email")} /></div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Place of work</span><input style={input} value={f.affiliation} onChange={set("affiliation")} placeholder="Institution / employer" /></div>
          <div><span style={label}>Designation</span><input style={input} value={f.designation} onChange={set("designation")} placeholder="e.g. Professor" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>LinkedIn</span><input style={input} value={f.linkedin} onChange={set("linkedin")} placeholder="https://linkedin.com/in/…" /></div>
          <div><span style={label}>X / Twitter</span><input style={input} value={f.twitter} onChange={set("twitter")} placeholder="https://x.com/…" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Google Scholar</span><input style={input} value={f.scholar} onChange={set("scholar")} placeholder="https://scholar.google.com/…" /></div>
          <div><span style={label}>Website</span><input style={input} value={f.website} onChange={set("website")} placeholder="https://" /></div>
        </div>
        <div><span style={label}>Short bio (text only)</span><textarea style={{ ...input, minHeight: 120, resize: "vertical", fontFamily: T.serif }} value={f.bio} onChange={set("bio")} placeholder="A few lines about your research and background." /></div>
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg === "Saved." ? "#1a7f37" : msg.includes("Process") ? T.muted : "#b00020", marginTop: 12 }}>{msg}</p>}
      <button onClick={save} disabled={busy} style={{ marginTop: 16, padding: "12px 24px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>{busy ? "Saving…" : "Save profile"}</button>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- public author profile /people/[id]
cat > src/app/people/"[id]"/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";
import Avatar from "@/components/Avatar";

export const dynamic = "force-dynamic";

const ROLE_LABEL: Record<string, string> = { ADMIN: "Administrator", CHIEF_EDITOR: "Editor-in-Chief", EDITOR: "Editor", AUTHOR: "Author" };

export default async function Person({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const u = await prisma.user.findUnique({
    where: { id },
    select: { id: true, name: true, role: true, affiliation: true, designation: true, bio: true, image: true, website: true, linkedin: true, twitter: true, scholar: true },
  });
  if (!u) notFound();
  const articles = await prisma.article.findMany({ where: { submittedById: id, status: "PUBLISHED" }, orderBy: { publishedAt: "desc" }, include: { section: { select: { name: true } } } });

  const socials: [string, string | null][] = [["LinkedIn", u.linkedin], ["X", u.twitter], ["Google Scholar", u.scholar], ["Website", u.website]];

  return (
    <main style={{ maxWidth: 780, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ display: "flex", gap: 22, alignItems: "flex-start", flexWrap: "wrap" }}>
        <Avatar image={u.image} name={u.name} size={110} />
        <div style={{ flex: 1, minWidth: 240 }}>
          <Eyebrow inverse>{ROLE_LABEL[u.role] ?? u.role}</Eyebrow>
          <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "8px 0 4px" }}>{u.name}</h1>
          {(u.designation || u.affiliation) && <div style={{ fontFamily: T.sans, fontSize: 14, color: T.ink }}>{[u.designation, u.affiliation].filter(Boolean).join(" · ")}</div>}
          {socials.some(([, v]) => v) && (
            <div style={{ display: "flex", gap: 14, marginTop: 10, flexWrap: "wrap" }}>
              {socials.filter(([, v]) => v).map(([lbl, v]) => (
                <a key={lbl} href={v!} target="_blank" rel="noopener noreferrer" style={{ fontFamily: T.sans, fontSize: 12.5, textDecoration: "underline", color: T.ink }}>{lbl} ↗</a>
              ))}
            </div>
          )}
        </div>
      </div>

      {u.bio && <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.6, color: "#222", margin: "24px 0", borderTop: `1px solid ${T.rule}`, paddingTop: 20 }}>{u.bio}</p>}

      {articles.length > 0 && (
        <>
          <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8, marginTop: 30 }}>Published in IJRI</h2>
          {articles.map((a) => (
            <Link key={a.id} href={`/articles/${a.id}`} style={{ display: "block", padding: "14px 0", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>{a.section.name}</div>
              <div className="cardtitle" style={{ fontFamily: T.serif, fontSize: 19, margin: "3px 0" }}>{a.title}</div>
              <div style={{ fontFamily: T.sans, fontSize: 13, color: T.ink }}>{a.authorNames}</div>
            </Link>
          ))}
        </>
      )}
    </main>
  );
}
IJRI_EOF

echo ""
echo "Profiles v2 written. Now run:  npx prisma db push  &&  npm run build"
echo "(db push drops the old orcid column and adds linkedin/twitter/scholar + review assignments)"
