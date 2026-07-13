import Link from "next/link";
import { T } from "@/lib/ui";
import { IconBook, IconFeather, IconShield, IconArrow } from "@/lib/icons";
import { auth, signOut } from "@/auth";
import { Providers } from "./providers";
import { getAccount } from "@/lib/account";
import BackendFab from "@/components/BackendFab";

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

const FOOTER_COLS: { head: string; icon: React.ReactNode; links: [string, string][] }[] = [
  { head: "The Journal", icon: <IconBook size={16} />, links: [["/about", "About"], ["/aims-scope", "Aims & Scope"], ["/editorial-board", "Editorial Board"], ["/archives", "Archives"], ["/sections", "Sections"]] },
  { head: "For Authors", icon: <IconFeather size={16} />, links: [["/for-authors", "Author Guidelines"], ["/login", "Submit a Manuscript"], ["/ethics", "Publication Ethics"], ["/copyright", "Copyright & Licensing"]] },
  { head: "Policies & Info", icon: <IconShield size={16} />, links: [["/privacy", "Privacy Policy"], ["/terms", "Terms & Conditions"], ["/contact", "Contact"]] },
];

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const acc = await getAccount();
  const user = session?.user as { name?: string | null } | undefined;

  return (
    <html lang="en">
      <body style={{ margin: 0, background: T.paper, color: T.ink }}>
        <style>{`
          * { box-sizing: border-box; }
          a { color: inherit; text-decoration: none; }
          .nav a:hover { background:${T.g200}; }
          .cardtitle { text-decoration: underline transparent; text-underline-offset: 3px; transition: text-decoration-color .15s; }
          a:hover .cardtitle { text-decoration-color: ${T.ink}; }
          .body h2 { font-family:${T.serif}; font-size:22px; margin:28px 0 10px; }
          .body p { font-family:${T.serif}; font-size:18.5px; line-height:1.68; margin:0 0 20px; color:#1a1a1a; }
          .body blockquote { font-family:${T.serif}; font-style:italic; border-left:3px solid ${T.ink}; margin:24px 0; padding:4px 0 4px 18px; color:#333; }
          .body p:first-of-type::first-letter { font-family:${T.serif}; float:left; font-size:62px; line-height:.82; padding:6px 10px 0 0; font-weight:600; }
          .footlink { color:${T.footerText}; display:flex; align-items:center; gap:6px; padding:5px 0; font-size:13.5px; transition:color .15s; }
          .footlink:hover { color:#fff; }
          .footlink .fa { opacity:0; transform:translateX(-4px); transition:all .15s; }
          .footlink:hover .fa { opacity:1; transform:translateX(0); }
          .linkbtn { background:none; border:none; padding:0; cursor:pointer; font:inherit; color:inherit; }
          @media (max-width:860px){ .leadgrid{grid-template-columns:1fr !important;} .cardgrid{grid-template-columns:1fr 1fr !important;} .memberrow{grid-template-columns:1fr !important;} .footgrid{grid-template-columns:1fr 1fr !important;} }
          @media (max-width:560px){ .cardgrid{grid-template-columns:1fr !important;} .utilbar{font-size:10px !important;} .footgrid{grid-template-columns:1fr !important;} }
        `}</style>

        <Providers>
          <header style={{ borderBottom: `3px double ${T.ink}`, background: T.paper }}>
            <div style={{ borderBottom: `1px solid ${T.rule}`, background: T.g50 }}>
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
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "22px 20px 15px", textAlign: "center" }}>
              <Link href="/" style={{ display: "inline-block" }}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/logo-stacked.png" alt="International Journal of Research and Innovation" style={{ height: "clamp(86px,15vw,130px)", width: "auto" }} />
              </Link>
            </div>
            <div style={{ borderTop: `1px solid ${T.ink}`, borderBottom: `1px solid ${T.ink}`, background: T.ink }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "8px 20px", textAlign: "center", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.08em", textTransform: "uppercase", color: T.paper }}>
                Current issue · {CURRENT}
              </div>
            </div>
            <nav className="nav" style={{ background: T.g100 }}>
              <div style={{ maxWidth: 1120, margin: "0 auto", padding: "0 12px", display: "flex", justifyContent: "center", flexWrap: "wrap" }}>
                {NAV.map(([href, label]) => (
                  <Link key={href} href={href} style={{ fontFamily: T.sans, fontSize: 12, letterSpacing: "0.05em", textTransform: "uppercase", padding: "10px 14px" }}>{label}</Link>
                ))}
              </div>
            </nav>
          </header>

          {children}
          <BackendFab loggedIn={!!acc} role={acc?.role ?? ""} />

          <footer style={{ background: T.footer, marginTop: 48 }}>
            <div style={{ maxWidth: 1120, margin: "0 auto", padding: "48px 20px 22px" }}>
              <div className="footgrid" style={{ display: "grid", gridTemplateColumns: "1.6fr 1fr 1fr 1fr", gap: 36 }}>
                <div>
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src="/logo-wide-white.png" alt="IJRI" style={{ height: 34, width: "auto" }} />
                  <p style={{ fontFamily: T.serif, fontSize: 14.5, lineHeight: 1.6, color: T.footerText, margin: "16px 0 0", maxWidth: 320 }}>
                    A multidisciplinary, double-blind peer-reviewed research journal publishing across the sciences, engineering, management, and the social sciences.
                  </p>
                  <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.g400, marginTop: 18 }}>
                    e-ISSN: applied for · Published on ijrein.org
                  </div>
                </div>
                {FOOTER_COLS.map((col) => (
                  <div key={col.head}>
                    <div style={{ display: "flex", alignItems: "center", gap: 7, color: "#fff", fontFamily: T.sans, fontSize: 12, letterSpacing: "0.1em", textTransform: "uppercase", fontWeight: 600, paddingBottom: 12, marginBottom: 6, borderBottom: `1px solid #2c2c30` }}>
                      {col.icon}<span>{col.head}</span>
                    </div>
                    {col.links.map(([href, label]) => (
                      <Link key={href} href={href} className="footlink" style={{ fontFamily: T.sans }}>
                        <span>{label}</span><span className="fa"><IconArrow size={13} /></span>
                      </Link>
                    ))}
                  </div>
                ))}
              </div>
              <div style={{ borderTop: `1px solid #2c2c30`, marginTop: 34, paddingTop: 20, display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 10, fontFamily: T.sans, fontSize: 11.5, letterSpacing: "0.05em", textTransform: "uppercase", color: T.g400 }}>
                <span>© 2026 International Journal of Research and Innovation</span>
                <span>All rights reserved · Content is copyright of the respective authors and the journal</span>
              </div>
            </div>
          </footer>
        </Providers>
      </body>
    </html>
  );
}
