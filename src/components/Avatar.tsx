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
