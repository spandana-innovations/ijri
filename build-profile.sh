#!/usr/bin/env bash
# ==========================================================================
# IJRI — (#12) user profiles. Adds profile fields, a profile editor in the
# backend, an update API, and the "My profile" menu item.
# Run in repo:  bash build-profile.sh  ->  npx prisma db push  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Profiles..."
mkdir -p prisma src/app/api/account/profile

# locate the dashboard folder (inside the backend route group if moved)
DASHDIR=""
for c in "src/app/(backend)/dashboard" "src/app/dashboard"; do
  [ -d "$c" ] && DASHDIR="$c" && break
done
[ -n "$DASHDIR" ] || { echo "ERROR: dashboard folder not found"; exit 1; }
mkdir -p "$DASHDIR/profile"
echo "  profile page -> $DASHDIR/profile"

# ---------------------------------------------------------------- schema (adds User profile fields)
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
  orcid         String?
  website       String?
  bio           String?  @db.Text
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
  id             String        @id @default(cuid())
  title          String
  abstract       String
  bodyHtml       String?       @db.Text
  coverImage     String?
  authorNames    String
  affiliation    String?
  status         ArticleStatus @default(SUBMITTED)
  editorFeedback String?       @db.Text
  revisionCount  Int           @default(0)
  section        Section       @relation(fields: [sectionId], references: [id])
  sectionId      String
  issue          Issue?        @relation(fields: [issueId], references: [id])
  issueId        String?
  startPage      Int?
  endPage        Int?
  doi            String?       @unique
  pdfKey         String?
  submittedBy    User          @relation("SubmittedBy", fields: [submittedById], references: [id])
  submittedById  String
  chiefEditor    User?         @relation("DecidedBy", fields: [chiefEditorId], references: [id])
  chiefEditorId  String?
  decidedAt      DateTime?
  reviews        Review[]
  purchases      ArticlePurchase[]
  events         ArticleEvent[]
  createdAt      DateTime      @default(now())
  publishedAt    DateTime?

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
IJRI_EOF

# ---------------------------------------------------------------- profile API (PATCH own record)
cat > src/app/api/account/profile/route.ts << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized } from "@/lib/auth";

export async function PATCH(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();

  const b = await req.json().catch(() => null);
  const data: Record<string, string> = {};
  for (const f of ["name", "affiliation", "designation", "orcid", "website", "bio", "image"]) {
    if (typeof b?.[f] === "string") data[f] = b[f].trim();
  }
  if (typeof b?.email === "string" && b.email.trim()) {
    const email = b.email.trim().toLowerCase();
    const existing = await prisma.user.findUnique({ where: { email }, select: { id: true } });
    if (existing && existing.id !== acc.id) return Response.json({ error: "That email is already in use" }, { status: 409 });
    data.email = email;
  }
  if (!data.name) return Response.json({ error: "Name is required" }, { status: 400 });

  await prisma.user.update({ where: { id: acc.id }, data });
  return Response.json({ ok: true });
}
IJRI_EOF

# ---------------------------------------------------------------- profile page (server)
cat > "$DASHDIR/profile/page.tsx" << 'IJRI_EOF'
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
    select: { name: true, email: true, affiliation: true, designation: true, orcid: true, website: true, bio: true, image: true, role: true },
  });
  if (!u) redirect("/login");
  return <ProfileForm user={u} />;
}
IJRI_EOF

# ---------------------------------------------------------------- profile form (client)
cat > "$DASHDIR/profile/ProfileForm.tsx" << 'IJRI_EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { T, Eyebrow } from "@/lib/ui";
import { IconUsers } from "@/lib/icons";

type U = { name: string; email: string; affiliation: string | null; designation: string | null; orcid: string | null; website: string | null; bio: string | null; image: string | null; role: string };

export default function ProfileForm({ user }: { user: U }) {
  const router = useRouter();
  const [f, setF] = useState({
    name: user.name ?? "", email: user.email ?? "", affiliation: user.affiliation ?? "",
    designation: user.designation ?? "", orcid: user.orcid ?? "", website: user.website ?? "",
    bio: user.bio ?? "", image: user.image ?? "",
  });
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState("");
  const set = (k: keyof typeof f) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => setF({ ...f, [k]: e.target.value });

  async function save() {
    setBusy(true); setMsg("");
    const r = await fetch("/api/account/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify(f) });
    setBusy(false);
    if (!r.ok) { const d = await r.json().catch(() => ({})); setMsg(d.error ?? "Could not save"); return; }
    setMsg("Saved."); router.refresh();
  }

  const input: React.CSSProperties = { width: "100%", fontFamily: T.sans, fontSize: 14, padding: "10px 12px", border: `1px solid ${T.ink}`, marginTop: 5, background: T.paper };
  const label: React.CSSProperties = { fontFamily: T.sans, fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted };
  const initials = (f.name || "?").split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase();

  return (
    <main>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconUsers size={22} /><Eyebrow inverse>My profile</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 18px" }}>My profile</h1>

      <div style={{ display: "flex", gap: 16, alignItems: "center", marginBottom: 22 }}>
        {f.image ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={f.image} alt="" style={{ width: 72, height: 72, objectFit: "cover", border: `1px solid ${T.rule}`, filter: "grayscale(1)" }} />
        ) : (
          <div style={{ width: 72, height: 72, background: T.ink, color: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 26 }}>{initials}</div>
        )}
        <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted }}>Role: {user.role.replace("_", " ").toLowerCase()}</div>
      </div>

      <div style={{ display: "grid", gap: 14, maxWidth: 620 }}>
        <div><span style={label}>Full name</span><input style={input} value={f.name} onChange={set("name")} /></div>
        <div><span style={label}>Email (your sign-in)</span><input style={input} type="email" value={f.email} onChange={set("email")} /></div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>Place of work</span><input style={input} value={f.affiliation} onChange={set("affiliation")} placeholder="Institution / employer" /></div>
          <div><span style={label}>Designation</span><input style={input} value={f.designation} onChange={set("designation")} placeholder="e.g. Professor" /></div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <div><span style={label}>ORCID</span><input style={input} value={f.orcid} onChange={set("orcid")} placeholder="0000-0000-0000-0000" /></div>
          <div><span style={label}>Website</span><input style={input} value={f.website} onChange={set("website")} placeholder="https://" /></div>
        </div>
        <div><span style={label}>Photo URL</span><input style={input} value={f.image} onChange={set("image")} placeholder="https://…/photo.jpg" /></div>
        <div><span style={label}>Short bio</span><textarea style={{ ...input, minHeight: 110, resize: "vertical", fontFamily: T.serif }} value={f.bio} onChange={set("bio")} placeholder="A few lines about your research and background." /></div>
      </div>

      {msg && <p style={{ fontFamily: T.sans, fontSize: 13, color: msg === "Saved." ? "#1a7f37" : "#b00020", marginTop: 12 }}>{msg}</p>}
      <button onClick={save} disabled={busy} style={{ marginTop: 16, padding: "12px 24px", background: T.ink, color: T.paper, border: "none", fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.07em", textTransform: "uppercase", cursor: "pointer", opacity: busy ? 0.6 : 1 }}>{busy ? "Saving…" : "Save profile"}</button>
    </main>
  );
}
IJRI_EOF

# ---------------------------------------------------------------- re-add "My profile" to the menu
if [ -f src/components/BackendNav.tsx ]; then
  node - << 'NODE'
const fs = require("fs"); const p = "src/components/BackendNav.tsx";
let s = fs.readFileSync(p, "utf8");
if (s.includes(`/dashboard/profile`)) { console.log("  nav already has My profile"); }
else {
  const anchor = `\n  return (`;
  const add = `\n  items.push({ href: "/dashboard/profile", label: "My profile", icon: <IconUsers size={16} /> });\n\n  return (`;
  if (s.includes(anchor)) { fs.writeFileSync(p, s.replace(anchor, add)); console.log("  nav: My profile added"); }
  else console.log("  WARN: could not locate nav return; add profile link manually");
}
NODE
fi

echo ""
echo "Profiles written. Now run:  npx prisma db push  &&  npm run build"
