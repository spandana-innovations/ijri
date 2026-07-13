import Link from "next/link";
import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { T, Eyebrow } from "@/lib/ui";
import { IconArrow } from "@/lib/icons";

export const dynamic = "force-dynamic";

type Stat = { n: number; label: string; href?: string; accent?: boolean };

export default async function Dashboard() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const role = acc.role;
  const isAdmin = role === "ADMIN" || role === "CHIEF_EDITOR";

  let stats: Stat[] = [];
  let actions: { href: string; label: string; desc: string }[] = [];

  if (isAdmin) {
    const [pending, queue, revisions, published, subs, views] = await Promise.all([
      prisma.user.count({ where: { approved: false } }),
      prisma.article.count({ where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } } }),
      prisma.article.count({ where: { status: "REVISION_REQUESTED" } }),
      prisma.article.count({ where: { status: "PUBLISHED" } }),
      prisma.subscription.count({ where: { status: "ACTIVE", endsAt: { gte: new Date() } } }),
      prisma.articleEvent.count({ where: { type: "VIEW" } }),
    ]);
    stats = [
      { n: pending, label: "Users awaiting approval", href: "/admin/users", accent: pending > 0 },
      { n: queue, label: "Manuscripts in the queue", href: "/editor", accent: queue > 0 },
      { n: revisions, label: "Out for revision" },
      { n: published, label: "Published articles" },
      { n: subs, label: "Active subscriptions" },
      { n: views, label: "Total article views", href: "/admin/analytics" },
    ];
    actions = [
      { href: "/admin/users", label: "User management", desc: "Approve users and manage roles." },
      { href: "/editor", label: "Review desk", desc: "Read manuscripts, record reviews, publish or reject." },
      { href: "/admin/analytics", label: "Application analytics", desc: "Views, downloads and engagement." },
    ];
  } else if (role === "EDITOR") {
    const [queue, myReviews] = await Promise.all([
      prisma.article.count({ where: { status: { in: ["SUBMITTED", "UNDER_REVIEW", "REVIEWED"] } } }),
      prisma.review.count({ where: { editorId: acc.id } }),
    ]);
    stats = [
      { n: queue, label: "Manuscripts in the queue", href: "/editor", accent: queue > 0 },
      { n: myReviews, label: "Reviews you've recorded" },
    ];
    actions = [{ href: "/editor", label: "Review desk", desc: "Open the queue and record your reviews." }];
  } else {
    const [mine, revisions, published] = await Promise.all([
      prisma.article.count({ where: { submittedById: acc.id } }),
      prisma.article.count({ where: { submittedById: acc.id, status: "REVISION_REQUESTED" } }),
      prisma.article.count({ where: { submittedById: acc.id, status: "PUBLISHED" } }),
    ]);
    stats = [
      { n: mine, label: "Your submissions", href: "/my-submissions" },
      { n: revisions, label: "Awaiting your revision", href: "/my-submissions", accent: revisions > 0 },
      { n: published, label: "Published" },
    ];
    actions = [
      { href: "/submit", label: "New submission", desc: "Submit a manuscript using the form." },
      { href: "/submit/word", label: "Upload Word document", desc: "Convert a .docx into the journal style." },
      { href: "/my-submissions", label: "My submissions", desc: "Track status and respond to editor feedback." },
    ];
  }

  return (
    <main>
      <style>{`.bk-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}@media(max-width:640px){.bk-stats{grid-template-columns:1fr 1fr}}@media(max-width:420px){.bk-stats{grid-template-columns:1fr}}`}</style>
      <Eyebrow inverse>Backend</Eyebrow>
      <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(24px,4vw,34px)", margin: "10px 0 20px" }}>Welcome, {acc.name.replace(/^(Dr|Prof|Mr|Mrs|Ms)\.?\s+/i, "").split(/\s+/)[0]}</h1>

      <div className="bk-stats">
        {stats.map((s, i) => {
          const inner = (
            <div style={{ border: s.accent ? `2px solid ${T.ink}` : `1px solid ${T.rule}`, padding: "18px", background: s.accent ? T.g50 : T.paper, height: "100%" }}>
              <div style={{ fontFamily: T.serif, fontSize: 36, fontWeight: 600, lineHeight: 1 }}>{s.n.toLocaleString()}</div>
              <div style={{ fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted, marginTop: 6 }}>{s.label}</div>
            </div>
          );
          return s.href ? <Link key={i} href={s.href}>{inner}</Link> : <div key={i}>{inner}</div>;
        })}
      </div>

      <h2 style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: T.muted, borderBottom: `1px solid ${T.rule}`, paddingBottom: 8, margin: "32px 0 4px" }}>Go to</h2>
      {actions.map((a) => (
        <Link key={a.href + a.label} href={a.href} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12, padding: "16px 4px", borderBottom: `1px solid ${T.rule}` }}>
          <span>
            <span className="cardtitle" style={{ fontFamily: T.serif, fontSize: 19, display: "block" }}>{a.label}</span>
            <span style={{ fontFamily: T.sans, fontSize: 13, color: T.muted }}>{a.desc}</span>
          </span>
          <IconArrow size={17} />
        </Link>
      ))}
    </main>
  );
}
