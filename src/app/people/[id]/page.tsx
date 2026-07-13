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
