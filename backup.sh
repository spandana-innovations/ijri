#!/usr/bin/env bash
# ==========================================================================
# IJRI — database backup.
#
# Takes a compressed, point-in-time snapshot of your Railway Postgres database
# and keeps the most recent 30 locally. Run it manually before risky changes,
# and/or on a schedule (cron / launchd / a Railway cron service).
#
# Requires the Postgres client tools (pg_dump). On macOS:  brew install libpq
#   then add to PATH:  export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
#
# Usage:
#   export DATABASE_URL="postgresql://...tokaido.proxy.rlwy.net:39354/railway"
#   bash backup.sh
#   # or let it read DATABASE_URL from a local .env file automatically
# ==========================================================================
set -euo pipefail

# --- resolve DATABASE_URL (env first, then .env) --------------------------
if [ -z "${DATABASE_URL:-}" ] && [ -f .env ]; then
  DATABASE_URL="$(grep -E '^DATABASE_URL=' .env | tail -1 | cut -d= -f2- | tr -d '"' | tr -d "'")"
fi
if [ -z "${DATABASE_URL:-}" ]; then
  echo "ERROR: DATABASE_URL is not set (export it, or put it in .env)." >&2
  echo "Use the PUBLIC Railway connection string (…proxy.rlwy.net:PORT/railway)." >&2
  exit 1
fi

if ! command -v pg_dump >/dev/null 2>&1; then
  echo "ERROR: pg_dump not found. Install Postgres client tools." >&2
  echo "  macOS:  brew install libpq && export PATH=\"/opt/homebrew/opt/libpq/bin:\$PATH\"" >&2
  exit 1
fi

RETAIN="${RETAIN:-30}"
DIR="backups"
mkdir -p "$DIR"
TS="$(date +%Y%m%d-%H%M%S)"
OUT="$DIR/ijri-$TS.dump"

echo "Backing up IJRI database → $OUT"
# -Fc = custom compressed format (restore with pg_restore). --no-owner keeps it portable.
pg_dump "$DATABASE_URL" -Fc --no-owner --no-privileges -f "$OUT"

SIZE="$(du -h "$OUT" | cut -f1)"
echo "✓ Wrote $OUT ($SIZE)"

# --- retention: keep the newest $RETAIN dumps -----------------------------
COUNT="$(ls -1t "$DIR"/ijri-*.dump 2>/dev/null | wc -l | tr -d ' ')"
if [ "$COUNT" -gt "$RETAIN" ]; then
  ls -1t "$DIR"/ijri-*.dump | tail -n +"$((RETAIN + 1))" | while read -r old; do
    echo "  removing old backup: $old"; rm -f "$old"
  done
fi
echo "✓ $((COUNT > RETAIN ? RETAIN : COUNT)) backup(s) retained in $DIR/"

cat << 'NOTES'

--------------------------------------------------------------------------
To RESTORE a backup into a database (DESTRUCTIVE — overwrites objects):
    pg_restore --clean --no-owner --no-privileges \
      -d "$DATABASE_URL" backups/ijri-YYYYMMDD-HHMMSS.dump

Recommended backup posture for a live journal with real data:
  1. Railway managed backups — enable automated daily snapshots on the
     Postgres service in the Railway dashboard (your first line of defence).
  2. This script on a schedule — a second, independent copy you control.
       cron example (daily 02:30, logs to backups/backup.log):
       30 2 * * * cd /path/to/ijri && /bin/bash backup.sh >> backups/backup.log 2>&1
  3. Off-site copy — sync the backups/ folder to object storage you own
     (e.g. your Cloudflare R2 / S3 bucket) so a Railway-side incident can't
     take your data and its only backups at once. Example:
       aws s3 sync backups/ s3://ijri-backups/ --exclude "*.log"
  4. Test a restore into a scratch database at least once — an untested
     backup is a hope, not a backup.

Keep the dump files private: they contain user records (including password
hashes). Do NOT commit backups/ to git — add it to .gitignore.
--------------------------------------------------------------------------
NOTES
