import Image from "next/image";
import Link from "next/link";

export function SiteHeader() {
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
        <Link href="/#features">Features</Link>
        <Link href="/privacy">Privacy</Link>
        <Link href="/support">Support</Link>
        <span className="review-pill">In App Review</span>
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
        <Link href="/privacy">Privacy</Link>
        <Link href="/support">Support</Link>
        <Link href="/terms">Terms</Link>
        <a href="https://github.com/Jenny-Media/FrameWink">GitHub</a>
      </nav>
      <p>© 2026 Jenny Media LLC. FrameWink supports iPhone and iPad only.</p>
    </footer>
  );
}
