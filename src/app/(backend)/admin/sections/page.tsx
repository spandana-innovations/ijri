import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import SectionManagement from "./SectionManagement";

export const dynamic = "force-dynamic";

export default async function SectionsPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") redirect("/dashboard");
  return <SectionManagement />;
}
