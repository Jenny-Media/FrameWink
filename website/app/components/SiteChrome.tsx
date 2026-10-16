import Image from "next/image";
import Link from "next/link";
import { ActiveNavLink } from "./ActiveNavLink";
import { HeaderMenuController } from "./HeaderMenuController";
import { appStoreURL } from "../siteMetadata";

function HeaderLinks() {
  return (
    <>
        <Link className="features-link" href="/#features">Features</Link>
        <ActiveNavLink href="/privacy">Privacy</ActiveNavLink>
        <ActiveNavLink href="/support">Support</ActiveNavLink>
        <a className="review-pill" href={appStoreURL}>Download</a>
    </>
  );
}

export function SiteHeader() {
  return (
    <header className="site-header">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <Link className="brand" href="/" aria-label="FrameWink home">
        <Image src="/images/framewink-icon.png" alt="" width={44} height={44} preload />
        <span>Frame<wbr />Wink</span>
      </Link>
      <nav className="desktop-nav" aria-label="Main navigation">
        <HeaderLinks />
      </nav>
      <button className="menu-toggle" type="button" hidden aria-label="Menu" aria-expanded="false" aria-controls="mobile-navigation">
        <svg className="menu-icon-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16" /></svg>
        <svg className="menu-icon-close" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" aria-hidden="true"><path d="m6 6 12 12M18 6 6 18" /></svg>
        <span>Menu</span>
      </button>
        <button className="theme-toggle" type="button" data-theme-toggle title="Change color theme">
          <svg className="theme-light-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden="true" focusable="false">
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2m0 16v2M2 12h2m16 0h2M4.93 4.93l1.42 1.42m11.3 11.3 1.42 1.42M4.93 19.07l1.42-1.42m11.3-11.3 1.42-1.42" strokeLinecap="round" />
          </svg>
          <svg className="theme-dark-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" aria-hidden="true" focusable="false">
            <path d="M20.9 13.3A9 9 0 0 1 10.7 3.1 9 9 0 1 0 20.9 13.3Z" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <span className="visually-hidden theme-light-label">Switch to dark theme</span>
          <span className="visually-hidden theme-dark-label">Switch to light theme</span>
        </button>
      <div className="mobile-panel" id="mobile-navigation">
        <nav aria-label="Main navigation"><HeaderLinks /></nav>
      </div>
      <HeaderMenuController />
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
          <span>A private photo frame for iPhone and iPad.</span>
        </div>
      </div>
      <nav aria-label="Footer navigation">
        <ActiveNavLink href="/privacy">Privacy</ActiveNavLink>
        <ActiveNavLink href="/support">Support</ActiveNavLink>
        <ActiveNavLink href="/terms">Terms</ActiveNavLink>
        <a href="https://github.com/Jenny-Media/FrameWink">GitHub</a>
        <a href="https://jenny.media/apps/">More apps by Jenny Media</a>
        <button className="theme-reset" type="button" data-theme-reset title="Follow your device’s light or dark appearance">
          Use system appearance
        </button>
      </nav>
      <div className="footer-legal">
        <p>© 2026 Jenny Media LLC. FrameWink supports iPhone and iPad only.</p>
        <p>Apple, the Apple logo, App Store, iPhone, and iPad are trademarks of Apple Inc., registered in the U.S. and other countries and regions.</p>
      </div>
    </footer>
  );
}
