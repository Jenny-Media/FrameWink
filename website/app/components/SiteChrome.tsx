import Image from "next/image";
import Link from "next/link";
import { ActiveNavLink } from "./ActiveNavLink";
import { appStoreURL } from "../siteMetadata";

export function SiteHeader() {
  return (
    <header className="site-header">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <Link className="brand" href="/" aria-label="FrameWink home">
        <Image src="/images/framewink-icon.png" alt="" width={44} height={44} preload />
        <span>FrameWink</span>
      </Link>
      <nav aria-label="Main navigation">
        <Link className="features-link" href="/#features">Features</Link>
        <ActiveNavLink href="/privacy">Privacy</ActiveNavLink>
        <ActiveNavLink href="/support">Support</ActiveNavLink>
        <a className="review-pill" href={appStoreURL}>Download</a>
      </nav>
    </header>
  );
}

export function SiteFooter() {
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
        <ActiveNavLink href="/privacy">Privacy</ActiveNavLink>
        <ActiveNavLink href="/support">Support</ActiveNavLink>
        <ActiveNavLink href="/terms">Terms</ActiveNavLink>
        <a href="https://github.com/Jenny-Media/FrameWink">GitHub</a>
      </nav>
      <div className="footer-legal">
        <p>© 2026 Jenny Media LLC. FrameWink supports iPhone and iPad only.</p>
        <p>Apple, the Apple logo, App Store, iPhone, and iPad are trademarks of Apple Inc., registered in the U.S. and other countries and regions.</p>
      </div>
    </footer>
  );
}
