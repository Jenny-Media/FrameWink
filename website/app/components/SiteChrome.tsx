"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

export function SiteHeader() {
  const pathname = usePathname();

  return (
    <header className="site-header">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <Link className="brand" href="/" aria-label="FrameWink home">
        <Image src="/images/framewink-icon.png" alt="" width={44} height={44} priority />
        <span>FrameWink</span>
      </Link>
      <nav aria-label="Main navigation">
        <Link className="features-link" href="/#features">Features</Link>
        <Link href="/privacy" aria-current={pathname === "/privacy" ? "page" : undefined}>Privacy</Link>
        <Link href="/support" aria-current={pathname === "/support" ? "page" : undefined}>Support</Link>
        {/* Native hash navigation transfers keyboard focus to the focusable target. */}
        {/* eslint-disable-next-line @next/next/no-html-link-for-pages */}
        <a className="review-pill" href="/#availability">In App Review</a>
      </nav>
    </header>
  );
}

export function SiteFooter() {
  const pathname = usePathname();

  return (
    <footer className="site-footer">
      <div className="footer-brand">
        <Image src="/images/framewink-icon.png" alt="" width={52} height={52} />
        <div>
          <strong>FrameWink</strong>
          <span>Private smart photo frame for iPhone and iPad.</span>
        </div>
      </div>
      <nav aria-label="Footer navigation">
        <Link href="/privacy" aria-current={pathname === "/privacy" ? "page" : undefined}>Privacy</Link>
        <Link href="/support" aria-current={pathname === "/support" ? "page" : undefined}>Support</Link>
        <Link href="/terms" aria-current={pathname === "/terms" ? "page" : undefined}>Terms</Link>
        <a href="https://github.com/Jenny-Media/FrameWink">GitHub</a>
      </nav>
      <p>© 2026 Jenny Media LLC. FrameWink supports iPhone and iPad only.</p>
    </footer>
  );
}
