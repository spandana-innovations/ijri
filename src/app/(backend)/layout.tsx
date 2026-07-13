import { redirect } from "next/navigation";
import { auth } from "@/auth";
import BackendNav from "@/components/BackendNav";

export default async function BackendLayout({ children }: { children: React.ReactNode }) {
  const session = await auth();
  const user = session?.user as { name?: string | null; role?: string } | undefined;
  if (!user) redirect("/login");

  return (
    <div className="bkshell">
      <style>{`
        .bkshell { max-width:1180px; margin:0 auto; padding:24px 16px; display:grid; grid-template-columns:230px 1fr; gap:24px; align-items:start; }
        .bkshell > .bkside { position:sticky; top:16px; }
        .bkshell > .bkmain { min-width:0; }
        @media (max-width:820px){ .bkshell{ grid-template-columns:1fr; } .bkshell > .bkside{ position:static; } }
      `}</style>
      <div className="bkside"><BackendNav role={user.role ?? ""} name={user.name ?? ""} /></div>
      <div className="bkmain">{children}</div>
    </div>
  );
}
