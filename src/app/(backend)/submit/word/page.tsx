import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import WordUpload from "./WordUpload";

export const dynamic = "force-dynamic";

export default async function WordUploadPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const sections = await prisma.section.findMany({ orderBy: { name: "asc" }, select: { id: true, name: true } });
  return <WordUpload sections={sections} defaultAuthor={acc.name} />;
}
