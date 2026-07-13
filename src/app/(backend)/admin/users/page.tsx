import { redirect } from "next/navigation";
import { getAccount } from "@/lib/account";
import UserManagement from "./UserManagement";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  if (acc.role !== "ADMIN" && acc.role !== "CHIEF_EDITOR") redirect("/dashboard");
  return <UserManagement />;
}
