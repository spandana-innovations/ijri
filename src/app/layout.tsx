import Link from "next/link";
import { T } from "@/lib/ui";
import { auth, signOut } from "@/auth";
import { Providers } from "./providers";

export const metadata = {
  title: "International Journal of Research and Innovation",
  description: "A multidisciplinary, double-blind peer-reviewed research journal.",
};

const CURRENT = "Volume 1, Issue 1 · July 2026";
const NAV: [string, string][] = [
  ["/", "Home"],
  ["/archives", "Archives"],
  ["/sections", "Sections"],
  ["/editorial-board", "Editorial Board"],
  ["/for-authors", "For Authors"],
];

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const user = session?.user as { name?: string | null } | undefined;

  return (
    <html lang="en">
      <body style={{ margin: 0, background: T.paper, color: T.ink }}>
        <style>{`
          * { box-sizing: border-box; }
          a { color: inherit; text-decoration: none; }
          .nav a:hover { background:#ececec; }
          .cardtitle { text-decoration: underline transparent; text-underline-offset: 3px; transition: text-decoration-color .15s; }
          a:hover .cardtitle { text-decoration-color: ${T.ink}; }
          .body h2 { font-family:${T.serif}; font-size:22px; margin:28px 0 10px; }
          .body p { font-family:${T.serif}; font-size:18.5px; line-height:1.68; margin:0 0 20px; color:#1a1a1a; }
          .body blockquote { font-family:${T.serif}; font-style:italic; border-left:3px solid ${T.ink}; margin:24px 0; padding:4px 0 4px 18px; color:#333; }
          .body p:first-of-type::first-letter { font-family:${T.serif}; float:left; font-size:62px; line-height:.82; padding:6px 10px 0 0; font-weight:600; }
          .linkbtn { background:none; border:none; padding:0; cursor:pointer; font:inherit; color:inherit; }
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} .utilbar{font-size:10px !important;} }
        `}</style>

        <Providers>
          <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
            <div style={{ borderBottom: `1px solid ${T.rule}` }}>
              <div className="utilbar" style={{ maxWidth: 1120, margin: "0 auto", padding: "0 20px", height: 34, display: "flex", alignItems: "center", justifyContent: "space-between", fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>
                <span>e-ISSN: applied for</span>
                {user ? (
                  <span style={{ display: "flex", gap: 10, alignItems: "center" }}>
                    <span style={{ color: T.ink }}>{user.name}</span>
                    <form action={async () => { "use server"; await signOut({ redirectTo: "/" }); }}>
                      <button className="linkbtn" style={{ textTransform: "uppercase", letterSpacing: "0.06em", textDecoration: "underline", textUnderlineOffset: 2 }}>Sign out</button>
                    </form>
                  </span>
                ) : (
                  <Link href="/login" style={{ textDecoration: "underline", textUnderlineOffset: 2 }}>Sign in</Link>
                )}
              </div>
            </div>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "20px 20px 14px", textAlign: "center" }}>
              <Link href="/" style={{ display: "inline-block" }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/logo-stacked.png" alt="International Journal of Research and Innovation" style={{ height: "clamp(64px,11vw,96px)", width: "auto" }} />
              </Link>
            </div>
            <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
                Current issue · {CURRENT}
              </div>
            </div>
            <nav className="nav" style={{ background: T.faint }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
                {NAV.map(([href, label]) => (
                  <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
                ))}
              </div>
            </nav>
          </header>

          {children}

          <footer style={{ borderTop: `1px solid ${T.ink}`, background: T.ink, marginTop: 40 }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "34px 20px", textAlign: "center" }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 30, width: "auto", opacity: 0.95 }} />
              <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: "#9a9a9a", marginTop: 16 }}>
                ijrein.org · e-ISSN applied for · © 2026 International Journal of Research and Innovation
              </div>
            </div>
          </footer>
        </Providers>
      </body>
    </html>
  );
}
