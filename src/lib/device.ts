// Coarse device classification from a User-Agent string. Deliberately lossy:
// we keep only a category, never the raw UA, IP, or any identifier.
export function deviceClass(ua: string | null | undefined): string {
  const s = (ua ?? "").toLowerCase();
  if (!s) return "unknown";
  if (/bot|crawler|spider|slurp|bingpreview|facebookexternalhit|headless/.test(s)) return "bot";
  if (/ipad|tablet|kindle|silk|playbook/.test(s)) return "tablet";
  if (/mobi|iphone|ipod|android.*mobile|windows phone/.test(s)) return "mobile";
  if (/android/.test(s)) return "tablet";
  return "desktop";
}
