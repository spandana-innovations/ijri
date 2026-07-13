"use client";
import { useEffect, useRef } from "react";

// Drop <TrackView articleId={article.id} /> into the article reader page.
// Fires exactly once per mount; no cookies, no identifiers.
export default function TrackView({ articleId }: { articleId: string }) {
  const done = useRef(false);
  useEffect(() => {
    if (done.current) return;
    done.current = true;
    const body = JSON.stringify({ articleId, type: "VIEW" });
    fetch("/api/track", { method: "POST", headers: { "Content-Type": "application/json" }, body, keepalive: true }).catch(() => {});
  }, [articleId]);
  return null;
}
