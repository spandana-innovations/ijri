import Link from "next/link";
import { T, Eyebrow } from "@/lib/ui";
import { IconFeather, IconShield, IconScale, IconDoc, IconUsers, IconArrow } from "@/lib/icons";

const GLANCE = [
  { icon: <IconShield size={18} />, h: "Double-blind", d: "Every manuscript is peer-reviewed anonymously." },
  { icon: <IconScale size={18} />, h: "APA 7", d: "References follow APA 7th edition style." },
  { icon: <IconDoc size={18} />, h: "Original work", d: "Unpublished and not under review elsewhere." },
  { icon: <IconUsers size={18} />, h: "Declarations", d: "Authorship and conflicts stated up front." },
];

const STEPS = [
  { t: "Title", d: "A precise, appealing title that conveys the subject so researchers can find and cite your work." },
  { t: "Abstract", d: "State the purpose, the methodology, the findings, and the conclusions — plus any trial registry name, number, or URL where applicable." },
  { t: "Keywords", d: "Keywords mirror the topic and are mandatory for identifying the core concepts of the study." },
  { t: "Acknowledgements", d: "Credit is acknowledged where due. Referencing throughout follows the APA 7 style." },
  { t: "Author contributions", d: "State each author’s contribution to the article, whether single- or multi-authored." },
  { t: "Statements & declarations", d: "A ‘No conflict of interest’ declaration must be signed by the sole author or by each author." },
];

export default function ForAuthors() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      {/* hero */}
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconFeather size={26} /></div>
        <div><Eyebrow inverse>For Authors</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>Guidelines for Authors</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 620, margin: "0 auto" }}>
          Prepare your manuscript against the essentials below. Every submission undergoes double-blind peer review.
        </p>
      </div>

      {/* at a glance */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 0, border: `1px solid ${T.rule}`, borderTop: "none", marginBottom: 44 }}>
        {GLANCE.map((g, i) => (
          <div key={g.h} style={{ padding: "18px 16px", borderLeft: i === 0 ? "none" : `1px solid ${T.rule}` }}>
            <div style={{ color: T.ink }}>{g.icon}</div>
            <div style={{ fontFamily: T.sans, fontSize: 13, fontWeight: 600, letterSpacing: "0.02em", color: T.ink, margin: "8px 0 3px" }}>{g.h}</div>
            <div style={{ fontFamily: T.sans, fontSize: 12, lineHeight: 1.45, color: T.muted }}>{g.d}</div>
          </div>
        ))}
      </div>

      {/* process timeline with connector */}
      <Eyebrow>What to include</Eyebrow>
      <div style={{ position: "relative", marginTop: 18 }}>
        <div style={{ position: "absolute", left: 23, top: 24, bottom: 24, width: 1, background: T.g300 }} />
        {STEPS.map((s, i) => (
          <div key={s.t} style={{ position: "relative", display: "grid", gridTemplateColumns: "48px 1fr", gap: 18, padding: "16px 0", alignItems: "start" }}>
            <div style={{ position: "relative", zIndex: 1, width: 48, height: 48, borderRadius: "50%", border: `1.5px solid ${T.ink}`, background: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 20, fontWeight: 600 }}>{i + 1}</div>
            <div style={{ paddingTop: 4 }}>
              <h3 style={{ fontFamily: T.serif, fontSize: 21, margin: "0 0 4px" }}>{s.t}</h3>
              <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.6, color: "#2a2a2a", margin: 0 }}>{s.d}</p>
            </div>
          </div>
        ))}
      </div>

      {/* CTA */}
      <div style={{ marginTop: 34, border: `2px solid ${T.ink}`, padding: "26px 26px", display: "flex", flexWrap: "wrap", gap: 16, alignItems: "center", justifyContent: "space-between", background: T.g50 }}>
        <div>
          <h3 style={{ fontFamily: T.serif, fontSize: 24, margin: "0 0 4px" }}>Ready to submit?</h3>
          <p style={{ fontFamily: T.sans, fontSize: 13.5, color: T.muted, margin: 0 }}>Manuscripts are screened for similarity per UGC guidelines before review.</p>
        </div>
        <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
          <Link href="/submit" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "13px 22px", background: T.ink, color: T.paper, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase" }}>Submit <IconArrow size={15} /></Link>
          <Link href="/submit/word" style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "13px 22px", background: T.paper, color: T.ink, border: `1px solid ${T.ink}`, fontFamily: T.sans, fontSize: 12.5, letterSpacing: "0.06em", textTransform: "uppercase" }}>Upload Word</Link>
        </div>
      </div>
    </main>
  );
}
