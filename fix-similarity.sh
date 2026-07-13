#!/usr/bin/env bash
# ==========================================================================
# IJRI — build fix: the editor detail page imports ./SimilarityPanel, ./ReviewDesk
# and ./AssignPanel. This ensures the similarity pieces exist (component + lib +
# API) so the module resolves. Safe to run repeatedly.
# Run in repo:  bash fix-similarity.sh  ->  npm run build
# ==========================================================================
set -euo pipefail
echo "Ensuring similarity files exist..."

BASE="src/app"
[ -d "src/app/(backend)" ] && BASE="src/app/(backend)"
mkdir -p src/lib "$BASE/editor/[id]" "src/app/api/submissions/[id]/similarity"
echo "  editor folder -> $BASE/editor/[id]"

# ---------------------------------------------------------------- similarity lib
cat > src/lib/similarity.ts << 'IJRI_EOF'
import { prisma } from "./prisma";

function normalize(s: string): string {
  return s.replace(/<[^>]+>/g, " ").replace(/&[a-z]+;/gi, " ").toLowerCase().replace(/[^a-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
}
function shingles(text: string, k = 5): Set<string> {
  const words = text.split(" ").filter(Boolean);
  const set = new Set<string>();
  for (let i = 0; i + k <= words.length; i++) set.add(words.slice(i, i + k).join(" "));
  return set;
}
function containment(target: Set<string>, other: Set<string>): number {
  if (target.size === 0) return 0;
  let inter = 0;
  for (const x of target) if (other.has(x)) inter++;
  return inter / target.size;
}

export type SimMatch = { articleId: string; title: string; score: number };

export async function computeSimilarity(id: string): Promise<{ score: number; matches: SimMatch[] } | null> {
  const target = await prisma.article.findUnique({ where: { id }, select: { id: true, title: true, abstract: true, bodyHtml: true } });
  if (!target) return null;
  const others = await prisma.article.findMany({ where: { id: { not: id } }, select: { id: true, title: true, abstract: true, bodyHtml: true } });
  const tSh = shingles(normalize(`${target.title} ${target.abstract} ${target.bodyHtml ?? ""}`));
  const matches: SimMatch[] = [];
  for (const o of others) {
    const oSh = shingles(normalize(`${o.title} ${o.abstract} ${o.bodyHtml ?? ""}`));
    const score = Math.round(containment(tSh, oSh) * 100);
    if (score > 0) matches.push({ articleId: o.id, title: o.title, score });
  }
  matches.sort((a, b) => b.score - a.score);
  return { score: matches[0]?.score ?? 0, matches: matches.slice(0, 5) };
}
IJRI_EOF

# ---------------------------------------------------------------- similarity API
cat > "src/app/api/submissions/[id]/similarity/route.ts" << 'IJRI_EOF'
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff, unauthorized, forbidden } from "@/lib/auth";
import { computeSimilarity } from "@/lib/similarity";

export async function GET(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  if (!isStaff(acc.role)) return forbidden("Editors only");
  const result = await computeSimilarity(id);
  if (result) {
    await prisma.article.update({ where: { id }, data: { similarityScore: result.score, similarityMatchesJson: JSON.stringify(result.matches) } }).catch(() => {});
  }
  return Response.json(result ?? { score: 0, matches: [] });
}
IJRI_EOF

# ---------------------------------------------------------------- SimilarityPanel component
cat > "$BASE/editor/[id]/SimilarityPanel.tsx" << 'IJRI_EOF'
"use client";
import { useEffect, useState } from "react";
import { T, Eyebrow } from "@/lib/ui";
import { IconScale } from "@/lib/icons";

type Match = { articleId: string; title: string; score: number };

export default function SimilarityPanel({ articleId }: { articleId: string }) {
  const [data, setData] = useState<{ score: number; matches: Match[] } | null>(null);
  const [loading, setLoading] = useState(true);

  async function run() {
    setLoading(true);
    try { const r = await fetch(`/api/submissions/${articleId}/similarity`); setData(await r.json()); } catch { /* ignore */ }
    setLoading(false);
  }
  useEffect(() => { run(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [articleId]);

  const score = data?.score ?? 0;
  const color = score >= 30 ? "#b00020" : score >= 15 ? "#b26a00" : "#1a7f37";
  const verdict = score >= 30 ? "High overlap — review closely" : score >= 15 ? "Some overlap" : "Low overlap";

  return (
    <div style={{ border: `1px solid ${T.ink}`, padding: "14px 16px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 9, color: T.ink }}><IconScale size={18} /><Eyebrow>Similarity · internal corpus</Eyebrow></div>
      {loading ? (
        <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, margin: "10px 0 0" }}>Checking against existing articles…</p>
      ) : (
        <>
          <div style={{ display: "flex", alignItems: "baseline", gap: 12, marginTop: 8 }}>
            <span style={{ fontFamily: T.serif, fontSize: 36, fontWeight: 600, color, lineHeight: 1 }}>{score}%</span>
            <span style={{ fontFamily: T.sans, fontSize: 12.5, color }}>{verdict}</span>
          </div>
          {data && data.matches.length > 0 ? (
            <div style={{ marginTop: 10 }}>
              <div style={{ fontFamily: T.sans, fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted, marginBottom: 4 }}>Closest matches</div>
              {data.matches.map((m) => (
                <div key={m.articleId} style={{ display: "flex", justifyContent: "space-between", gap: 10, fontFamily: T.sans, fontSize: 13, padding: "6px 0", borderTop: `1px solid ${T.rule}` }}>
                  <a href={`/articles/${m.articleId}`} style={{ textDecoration: "underline" }}>{m.title}</a>
                  <span style={{ color: T.muted }}>{m.score}%</span>
                </div>
              ))}
            </div>
          ) : (
            <p style={{ fontFamily: T.sans, fontSize: 13, color: T.muted, marginTop: 8 }}>No meaningful overlap with existing articles.</p>
          )}
          <p style={{ fontFamily: T.sans, fontSize: 11, lineHeight: 1.5, color: T.muted, marginTop: 10 }}>
            Compares only against articles in this journal — not the open web.
            <button onClick={run} style={{ marginLeft: 8, background: "none", border: "none", padding: 0, textDecoration: "underline", cursor: "pointer", fontFamily: T.sans, fontSize: 11, color: T.ink }}>Recheck</button>
          </p>
        </>
      )}
    </div>
  );
}
IJRI_EOF

echo ""
echo "Similarity files ensured. Now run:  npm run build"
