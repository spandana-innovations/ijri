import { prisma } from "./prisma";
import type { EventType } from "@prisma/client";

// Fire-and-forget. Never throws into the request path; analytics must never
// break a page render or a download.
export async function recordEvent(articleId: string, type: EventType, device?: string) {
  try {
    await prisma.articleEvent.create({ data: { articleId, type, device: device ?? null } });
  } catch {
    /* swallow — analytics is best-effort */
  }
}
