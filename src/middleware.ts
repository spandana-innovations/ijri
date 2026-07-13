import { NextResponse, type NextRequest } from "next/server";

export const config = { matcher: ["/articles/:id", "/api/articles/:id/pdf"] };

export function middleware(req: NextRequest) {
  const res = NextResponse.next();
  // ignore prefetches so hovering a link doesn't inflate counts
  if (req.headers.get("next-router-prefetch") || req.headers.get("purpose") === "prefetch") return res;

  const path = req.nextUrl.pathname;
  let articleId = "";
  let type: "VIEW" | "DOWNLOAD" | "" = "";
  let m = path.match(/^\/articles\/([^/]+)$/);
  if (m) { articleId = m[1]; type = "VIEW"; }
  else { m = path.match(/^\/api\/articles\/([^/]+)\/pdf$/); if (m) { articleId = m[1]; type = "DOWNLOAD"; } }

  if (articleId && type) {
    // fire-and-forget to our own tracking endpoint; forward the real UA
    fetch(req.nextUrl.origin + "/api/track", {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-ua": req.headers.get("user-agent") ?? "" },
      body: JSON.stringify({ articleId, type }),
    }).catch(() => {});
  }
  return res;
}
