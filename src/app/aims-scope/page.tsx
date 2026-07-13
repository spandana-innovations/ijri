import { T, Eyebrow } from "@/lib/ui";
import { IconLayers, IconDoc, IconBook, IconScale, IconShield, IconUsers, IconFeather } from "@/lib/icons";

const SUBJECTS = [
  { icon: <IconDoc size={20} />, name: "Computer & Information Science" },
  { icon: <IconShield size={20} />, name: "Medicine & Public Health" },
  { icon: <IconLayers size={20} />, name: "Engineering" },
  { icon: <IconScale size={20} />, name: "Economics & Management" },
  { icon: <IconBook size={20} />, name: "Materials Science" },
  { icon: <IconUsers size={20} />, name: "Social Sciences" },
];

const TYPES = [
  { h: "Original research", d: "Full-length articles presenting new, methodologically sound findings." },
  { h: "Systematic reviews", d: "Structured syntheses that map and evaluate a body of evidence." },
  { h: "Scholarly commentary", d: "Considered perspectives on questions of significance to a field." },
];

export default function AimsScope() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconLayers size={26} /></div>
        <div><Eyebrow inverse>Aims & Scope</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>Aims &amp; Scope</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 640, margin: "0 auto" }}>
          IJRI advances rigorous, original scholarship and makes it accessible to researchers, practitioners, and policymakers.
        </p>
      </div>

      <Eyebrow>Subject areas</Eyebrow>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14, margin: "14px 0 40px" }}>
        {SUBJECTS.map((s) => (
          <div key={s.name} style={{ border: `1px solid ${T.rule}`, padding: "20px 16px", textAlign: "center", background: T.paper }}>
            <div style={{ display: "flex", justifyContent: "center", color: T.ink, marginBottom: 10 }}>{s.icon}</div>
            <div style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.3 }}>{s.name}</div>
          </div>
        ))}
      </div>

      <Eyebrow>Article types</Eyebrow>
      <div style={{ margin: "14px 0 34px" }}>
        {TYPES.map((t, i) => (
          <div key={t.h} style={{ display: "grid", gridTemplateColumns: "1fr", gap: 2, padding: "16px 0", borderTop: `1px solid ${T.rule}`, borderBottom: i === TYPES.length - 1 ? `1px solid ${T.rule}` : "none" }}>
            <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: 0 }}>{t.h}</h3>
            <p style={{ fontFamily: T.sans, fontSize: 14, lineHeight: 1.55, color: T.muted, margin: 0 }}>{t.d}</p>
          </div>
        ))}
      </div>

      <div style={{ border: `2px solid ${T.ink}`, padding: "20px 22px", display: "flex", gap: 14, alignItems: "center", background: T.g50 }}>
        <IconFeather size={22} />
        <p style={{ fontFamily: T.serif, fontSize: 16.5, lineHeight: 1.55, margin: 0 }}>
          All submissions are prepared per the guidelines for authors and undergo double-blind peer review.
        </p>
      </div>
    </main>
  );
}
