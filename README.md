# IJRI — backend

International Journal of Research and Innovation. Next.js (App Router) + Prisma + Postgres on Railway. Full text is gated by a server-side subscription paywall; abstracts and metadata stay public.

- `prisma/schema.prisma` — data model (users/roles, sections, issues, articles, reviews, subscriptions, purchases).
- `src/lib/entitlements.ts` — the paywall; the server decides who may read.
- `src/lib/storage.ts` — S3-compatible storage (Railway Bucket or Cloudflare R2), signed PDF URLs.
- `src/app/api/**` — editorial workflow (submit → review → chief publish) and gated reads.

Auth in `src/lib/auth.ts` is a stub — wire NextAuth / Better Auth before launch.
See the chat for Railway setup steps.
