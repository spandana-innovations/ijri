import React from "react";

type P = { size?: number; stroke?: number; style?: React.CSSProperties };
const base = (size: number, stroke: number): React.SVGProps<SVGSVGElement> => ({
  width: size, height: size, viewBox: "0 0 24 24", fill: "none",
  stroke: "currentColor", strokeWidth: stroke, strokeLinecap: "round", strokeLinejoin: "round",
});

export const IconBook = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M4 5a2 2 0 0 1 2-2h9v16H6a2 2 0 0 0-2 2z" /><path d="M15 3h3a2 2 0 0 1 2 2v14a2 2 0 0 0-2-2h-3" /></svg>
);
export const IconDoc = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M6 2h8l4 4v16H6z" /><path d="M14 2v4h4" /><path d="M9 13h6M9 17h6" /></svg>
);
export const IconUsers = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><circle cx="9" cy="8" r="3" /><path d="M3 20a6 6 0 0 1 12 0" /><path d="M16 6a3 3 0 0 1 0 6M21 20a6 6 0 0 0-4-5.7" /></svg>
);
export const IconMail = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="3" y="5" width="18" height="14" rx="2" /><path d="m3 7 9 6 9-6" /></svg>
);
export const IconShield = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M12 3 5 6v5c0 4 3 7 7 9 4-2 7-5 7-9V6z" /><path d="m9 12 2 2 4-4" /></svg>
);
export const IconScale = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M12 3v18M7 21h10" /><path d="M12 5 5 8l-2 5a4 4 0 0 0 8 0L9 8M12 5l7 3 2 5a4 4 0 0 1-8 0l2-5" /></svg>
);
export const IconLayers = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="m12 3 9 5-9 5-9-5z" /><path d="m3 13 9 5 9-5" /></svg>
);
export const IconArchive = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="3" y="4" width="18" height="4" rx="1" /><path d="M5 8v11a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V8" /><path d="M10 12h4" /></svg>
);
export const IconFeather = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M20 4a7 7 0 0 0-10 0L4 10v10h10l6-6a7 7 0 0 0 0-4" /><path d="M16 8 4 20M16 12H9" /></svg>
);
export const IconLock = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V8a4 4 0 0 1 8 0v3" /></svg>
);
export const IconArrow = ({ size = 18, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><path d="M5 12h14M13 6l6 6-6 6" /></svg>
);
export const IconInfo = ({ size = 20, stroke = 1.5, style }: P) => (
  <svg {...base(size, stroke)} style={style}><circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 8h.01" /></svg>
);
