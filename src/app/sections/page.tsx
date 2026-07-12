import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";

export const dynamic = "force-dynamic";

export default async function Sections() {
  const sections = await prisma.section.findMany({
    orderBy: { name: "asc" },
    include: { articles: { where: { status: "PUBLISHED" }, select: { id: true } } },
  });

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <Eyebrow inverse>Sections</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 8px" }}>Browse by section</h1>
      <p style={{ fontFamily: T.serif, fontSize: 17, lineHeight: 1.55, color: "#333", margin: "0 0 24px" }}>
        The journal publishes across the sciences, engineering, management, and the social sciences.
      </p>
      <div style={{ borderTop: `1px solid ${T.ink}` }}>
        {sections.map((s) => (
          <Link key={s.id} href={`/sections/${s.slug}`} style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
            <span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 21 }}>{s.name}</span>
            <span style={{ fontFamily: T.sans, fontSize: 12.5, color: T.muted, textTransform: "uppercase", letterSpacing: "0.06em" }}>{s.articles.length} article{s.articles.length === 1 ? "" : "s"}</span>
          </Link>
        ))}
      </div>
    </main>
  );
}
