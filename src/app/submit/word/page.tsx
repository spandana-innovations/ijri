import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import WordSubmit from "./WordSubmit";

export const dynamic = "force-dynamic";

export default async function WordSubmitPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!acc.approved && !isStaff(acc.role)) redirect("/pending");
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, select: { id: true, name: true } });
  return <WordSubmit sections={sections} defaultAuthor={acc.name} defaultAffiliation={acc.affiliation ?? ""} />;
}
