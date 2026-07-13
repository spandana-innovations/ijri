import Link from "next/link";
import { prisma } from "@/lib/prisma";
import { T, Eyebrow } from "@/lib/ui";
import { IconLayers, IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

export default async function Sections() {
  const sections = await prisma.section.findMany({
    orderBy: { name: "asc" },
    include: { articles: { where: { status: "PUBLISHED" }, select: { id: true } } },
  });
  const counts = sections.map((s) => s.articles.length);
  const max = Math.max(1, ...counts);
  const total = counts.reduce((a, b) => a + b, 0);

  return (
    <main style={{ maxWidth: 900, margin: "0 auto", padding: "40px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: T.ink }}><IconLayers size={22} /><Eyebrow inverse>Sections</Eyebrow></div>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(26px,4.4vw,38px)", margin: "14px 0 4px" }}>Browse by section</h1>
      <p style={{ fontFamily: T.sans, fontSize: 13, letterSpacing: "0.04em", textTransform: "uppercase", color: T.muted, margin: "0 0 26px" }}>
        {sections.length} sections · {total} published articles
      </p>

      <div style={{ borderTop: `1px solid ${T.ink}` }}>
        {sections.map((s) => {
          const n = s.articles.length;
          const pct = Math.round((n / max) * 100);
          return (
            <Link key={s.id} href={`/sections/${s.slug}`} style={{ display: "block", padding: "20px 4px", borderBottom: `1px solid ${T.rule}` }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", marginBottom: 10 }}>
                <span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 22 }}>{s.name}</span>
                <span style={{ display: "flex", alignItems: "baseline", gap: 8 }}>
                  <span style={{ fontFamily: T.serif, fontSize: 34, fontWeight: 600, lineHeight: 1 }}>{n}</span>
                  <span style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase", color: T.muted }}>article{n === 1 ? "" : "s"}</span>
                  <IconArrow size={16} style={{ marginLeft: 4, color: T.muted }} />
                </span>
              </div>
              <div style={{ height: 8, background: T.g200, position: "relative", overflow: "hidden" }}>
                <div style={{ position: "absolute", inset: 0, width: `${pct}%`, background: T.ink }} />
              </div>
            </Link>
          );
        })}
      </div>
    </main>
  );
}
