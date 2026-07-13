"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { T } from "@/lib/ui";
import { IconLayers, IconDoc, IconFeather, IconUsers, IconShield, IconInfo, IconArchive } from "@/lib/icons";

type Item = { href: string; label: string; icon: React.ReactNode };

const ROLE_LABEL: Record<string, string> = { ADMIN: "Administrator", CHIEF_EDITOR: "Editor-in-Chief", EDITOR: "Editor", AUTHOR: "Author" };

export default function BackendNav({ role, name }: { role: string; name: string }) {
  const path = usePathname();
  const items: Item[] = [{ href: "/dashboard", label: "Overview", icon: <IconLayers size={16} /> }];

  if (role === "AUTHOR") {
    items.push(
      { href: "/my-submissions", label: "My submissions", icon: <IconDoc size={16} /> },
      { href: "/submit", label: "New submission", icon: <IconFeather size={16} /> },
      { href: "/submit/word", label: "Upload Word doc", icon: <IconArchive size={16} /> },
    );
  }
  if (role === "EDITOR") {
    items.push({ href: "/editor", label: "Review desk", icon: <IconDoc size={16} /> });
  }
  if (role === "CHIEF_EDITOR" || role === "ADMIN") {
    items.push(
      { href: "/editor", label: "Review desk", icon: <IconDoc size={16} /> },
      { href: "/admin", label: "Admin panel", icon: <IconUsers size={16} /> },
      { href: "/admin/analytics", label: "Analytics", icon: <IconInfo size={16} /> },
    );
  }

  return (
    <nav aria-label="Backend" style={{ fontFamily: T.sans }}>
      <div style={{ border: `1px solid ${T.rule}`, background: T.g50, padding: "14px 14px 8px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, paddingBottom: 12, borderBottom: `1px solid ${T.rule}`, marginBottom: 8 }}>
          <span style={{ width: 34, height: 34, background: T.ink, color: T.paper, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: T.serif, fontSize: 15 }}>
            {name.split(/\s+/).map((w) => w[0]).slice(0, 2).join("").toUpperCase()}
          </span>
          <span>
            <span style={{ display: "block", fontSize: 13, color: T.ink, lineHeight: 1.2 }}>{name}</span>
            <span style={{ display: "block", fontSize: 11, letterSpacing: "0.06em", textTransform: "uppercase", color: T.muted }}>{ROLE_LABEL[role] ?? role}</span>
          </span>
        </div>
        {items.map((it) => {
          const active = path === it.href;
          return (
            <Link key={it.href + it.label} href={it.href} style={{
              display: "flex", alignItems: "center", gap: 10, padding: "10px 10px", marginBottom: 2,
              fontSize: 13.5, color: active ? T.paper : T.ink, background: active ? T.ink : "transparent",
            }}>
              <span style={{ opacity: active ? 1 : 0.7, display: "inline-flex" }}>{it.icon}</span>{it.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
