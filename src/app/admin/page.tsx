import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import { isStaff } from "@/lib/auth";
import AdminPanel from "./AdminPanel";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (!isStaff(acc.role)) redirect("/");
  return <AdminPanel me={{ name: acc.name, role: acc.role }} />;
}
