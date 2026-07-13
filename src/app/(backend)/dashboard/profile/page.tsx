import { redirect } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { getAccount } from "@/lib/account";
import ProfileForm from "./ProfileForm";

export const dynamic = "force-dynamic";

export default async function ProfilePage() {
  const acc = await getAccount();
  if (!acc) redirect("/login");
  const u = await prisma.user.findUnique({
    where: { id: acc.id },
    select: { name: true, email: true, affiliation: true, designation: true, orcid: true, website: true, bio: true, image: true, role: true },
  });
  if (!u) redirect("/login");
  return <ProfileForm user={u} />;
}
