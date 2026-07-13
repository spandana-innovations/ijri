import { T, Eyebrow } from "@/lib/ui";
import { IconBook, IconUsers, IconLock, IconLayers, IconShield } from "@/lib/icons";

const FEATURES = [
  { icon: <IconUsers size={20} />, h: "Double-blind peer review", d: "Every submission is evaluated anonymously by the editorial board; accepted articles are published by the Editor-in-Chief, with reviewing editors recorded on each article." },
  { icon: <IconLayers size={20} />, h: "Genuinely multidisciplinary", d: "Research across the sciences, engineering, management, and the social sciences sits side by side in a single scholarly record." },
  { icon: <IconLock size={20} />, h: "Open abstracts, subscriber full text", d: "Abstracts and metadata are free to everyone; full texts are available to subscribers and authorised members." },
  { icon: <IconShield size={20} />, h: "A permanent record", d: "Articles are archived by volume and issue with stable bibliographic details for citation." },
];

export default function About() {
  return (
    <main style={{ maxWidth: 860, margin: "0 auto", padding: "44px 20px 60px" }}>
      <div style={{ textAlign: "center", borderBottom: `1px solid ${T.ink}`, paddingBottom: 26 }}>
        <div style={{ display: "inline-flex", alignItems: "center", justifyContent: "center", width: 58, height: 58, border: `1.5px solid ${T.ink}`, borderRadius: "50%", marginBottom: 14 }}><IconBook size={26} /></div>
        <div><Eyebrow inverse>About</Eyebrow></div>
        <h1 style={{ fontFamily: T.serif, fontWeight: 600, fontSize: "clamp(30px,5.5vw,50px)", lineHeight: 1.05, margin: "10px 0 10px" }}>About the Journal</h1>
        <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.55, color: "#333", maxWidth: 640, margin: "0 auto" }}>
          The International Journal of Research and Innovation is a multidisciplinary, double-blind peer-reviewed research journal.
        </p>
      </div>

      <p style={{ fontFamily: T.serif, fontSize: 18.5, lineHeight: 1.68, color: "#1a1a1a", margin: "30px 0" }}>
        IJRI publishes original research, reviews, and scholarly commentary across the sciences, engineering, management, and the social sciences — advancing rigorous work and making it accessible to researchers, practitioners, and policymakers.
      </p>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
        {FEATURES.map((f) => (
          <div key={f.h} style={{ border: `1px solid ${T.rule}`, padding: "20px 20px", background: T.paper }}>
            <div style={{ color: T.ink }}>{f.icon}</div>
            <h3 style={{ fontFamily: T.serif, fontSize: 20, margin: "10px 0 6px" }}>{f.h}</h3>
            <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.6, color: T.muted, margin: 0 }}>{f.d}</p>
          </div>
        ))}
      </div>

      <blockquote style={{ margin: "40px 0", padding: "6px 0 6px 22px", borderLeft: `3px solid ${T.ink}`, fontFamily: T.serif, fontStyle: "italic", fontSize: 22, lineHeight: 1.5, color: "#222" }}>
        Rigorous scholarship, openly indexed and permanently archived — so good research is easy to find, cite, and build upon.
      </blockquote>

      <div style={{ border: `1px solid ${T.ink}`, padding: "18px 20px", display: "flex", gap: 14, alignItems: "center", background: T.g50 }}>
        <IconShield size={20} />
        <p style={{ fontFamily: T.sans, fontSize: 13.5, lineHeight: 1.55, color: T.ink, margin: 0 }}>
          <strong>Publisher.</strong> IJRI is published online at ijrein.org and maintains a permanent editorial office for all correspondence.
        </p>
      </div>
    </main>
  );
}
