import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { unauthorized } from "@/lib/auth";
import type { PlanType } from "@prisma/client";

const PLANS: Record<PlanType, { days: number; print?: boolean }> = {
  MONTHLY: { days: 30 },
  ANNUAL: { days: 365 },
  PRINT_DIGITAL: { days: 365, print: true },
  SECTION: { days: 365 },
};

export async function POST(req: Request) {
  const acc = await getAccount(req);
  if (!acc) return unauthorized();
  const b = await req.json().catch(() => null);
  const plan = String(b?.plan ?? "") as PlanType;
  if (!(plan in PLANS)) return Response.json({ error: "Invalid plan" }, { status: 400 });

  const sectionId = plan === "SECTION" ? String(b?.sectionId ?? "") : null;
  if (plan === "SECTION" && !sectionId) return Response.json({ error: "Choose a section" }, { status: 400 });

  const cfg = PLANS[plan];
  const endsAt = new Date(Date.now() + cfg.days * 86400000);

  // Launch mode: grant access immediately. Replace with a payment callback later.
  const sub = await prisma.subscription.create({
    data: { userId: acc.id, plan, status: "ACTIVE", print: Boolean(cfg.print), sectionId, endsAt },
    select: { id: true, plan: true, endsAt: true },
  });
  return Response.json(sub, { status: 201 });
}
