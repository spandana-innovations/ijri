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
