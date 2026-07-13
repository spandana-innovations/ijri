#!/usr/bin/env bash
# ==========================================================================
# IJRI — editorial board with CLICKABLE names (#3).
# DB-driven: reads Chief Editor + Editors from user accounts, each linking to
# their /people/[id] profile. Stays in sync with User management.
# (Requires build-profile2.sh already run: Avatar + /people/[id].)
# Run in repo:  bash build-board.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Clickable editorial board..."
mkdir -p src/app/editorial-board

cat > src/app/editorial-board/page.tsx << 'IJRI_EOF'
import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";
import { IconShield } from "@/lib/icons";
import Avatar from "@/components/Avatar";

export const dynamic = "force-dynamic";

const SUPER = "info@ijrein.org";

type Member = { id: string; name: string; designation: string | null; affiliation: string | null; bio: string | null; image: string | null; linkedin: string | null; twitter: string | null; scholar: string | null; website: string | null };

function Socials({ m }: { m: Member }) {
  const links: [string, string | null][] = [["LinkedIn", m.linkedin], ["X", m.twitter], ["Scholar", m.scholar], ["Web", m.website]];
  const shown = links.filter(([, v]) => v);
  if (!shown.length) return null;
  return (
    <div style={{ display: "flex", gap: 12, marginTop: 8, flexWrap: "wrap" }}>
      {shown.map(([lbl, v]) => <a key={lbl} href={v!} target="_blank" rel="noopener noreferrer" style={{ fontFamily: T.sans, fontSize: 11.5, textDecoration: "underline", color: T.ink }}>{lbl} ↗</a>)}
    </div>
  );
}

export default async function EditorialBoard() {
  const chief = await prisma.user.findFirst({ where: { role: "CHIEF_EDITOR", approved: true, email: { not: SUPER } }, select: { id: true, name: true, designation: true, affiliation: true, bio: true, image: true, linkedin: true, twitter: true, scholar: true, website: true } });
  const editors = await prisma.user.findMany({ where: { role: "EDITOR", approved: true, email: { not: SUPER } }, orderBy: { name: "asc" }, select: { id: true, name: true, designation: true, affiliation: true, bio: true, image: true, linkedin: true, twitter: true, scholar: true, website: true } });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconShield size={22} /><Eyebrow inverse>Editorial Board</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(28px,5vw,44px)", margin: "12px 0 6px" }}>Editorial Board</h1>
      <p style={{ fontFamily: T.serif, fontSize: 18, color: "#333", maxWidth: 640, lineHeight: 1.55, margin: "0 0 8px" }}>The scholars who steward peer review and uphold the standards of the journal. Select a name to view their full profile.</p>

      {chief && (
        <section style={{ marginTop: 34, borderTop: `2px solid ${T.ink}`, paddingTop: 24 }}>
          <Eyebrow>Editor-in-Chief</Eyebrow>
          <div style={{ display: "flex", gap: 22, alignItems: "flex-start", marginTop: 14, flexWrap: "wrap" }}>
            <Link href={`/people/${chief.id}`}><Avatar image={chief.image} name={chief.name} size={120} /></Link>
            <div style={{ flex: 1, minWidth: 260 }}>
              <Link href={`/people/${chief.id}`} className="cardtitle" style={{ fontFamily: T.serif, fontSize: 26, fontWeight: 600 }}>{chief.name}</Link>
              {(chief.designation || chief.affiliation) && <div style={{ fontFamily: T.sans, fontSize: 14, color: T.ink, marginTop: 4 }}>{[chief.designation, chief.affiliation].filter(Boolean).join(" · ")}</div>}
              {chief.bio && <p style={{ fontFamily: T.serif, fontSize: 16, lineHeight: 1.6, color: "#333", margin: "12px 0 0" }}>{chief.bio}</p>}
              <Socials m={chief} />
            </div>
          </div>
        </section>
      )}

      <section style={{ marginTop: 40 }}>
        <Eyebrow>Editors</Eyebrow>
        {editors.length === 0 ? (
          <p style={{ fontFamily: T.serif, fontSize: 17, color: T.muted, marginTop: 14 }}>Editors will appear here as they are appointed. Add them under User management.</p>
        ) : (
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 22, marginTop: 16 }}>
            {editors.map((m) => (
              <div key={m.id} style={{ borderTop: `1px solid ${T.ink}`, paddingTop: 16 }}>
                <div style={{ display: "flex", gap: 14, alignItems: "flex-start" }}>
                  <Link href={`/people/${m.id}`}><Avatar image={m.image} name={m.name} size={60} /></Link>
                  <div style={{ minWidth: 0 }}>
                    <Link href={`/people/${m.id}`} className="cardtitle" style={{ fontFamily: T.serif, fontSize: 19, fontWeight: 600 }}>{m.name}</Link>
                    {(m.designation || m.affiliation) && <div style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, marginTop: 2 }}>{[m.designation, m.affiliation].filter(Boolean).join(" · ")}</div>}
                  </div>
                </div>
                {m.bio && <p style={{ fontFamily: T.serif, fontSize: 14.5, lineHeight: 1.55, color: "#444", margin: "10px 0 0" }}>{m.bio.length > 180 ? m.bio.slice(0, 180) + "…" : m.bio}</p>}
                <Socials m={m} />
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
IJRI_EOF

echo ""
echo "Editorial board written. Now run:  npm run build"
