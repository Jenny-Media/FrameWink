"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";

type ActiveNavLinkProps = {
  children: ReactNode;
  href: string;
};

export function ActiveNavLink({ children, href }: ActiveNavLinkProps) {
  const pathname = usePathname();

  return (
    <Link href={href} aria-current={pathname === href ? "page" : undefined}>
      {children}
    </Link>
  );
}
