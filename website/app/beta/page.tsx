import type { Metadata } from "next";
import { pageMetadata } from "../siteMetadata";

export const metadata: Metadata = {
  ...pageMetadata(
    "Beta",
    "Try early versions of FrameWink for iPhone and iPad through TestFlight.",
    "/beta",
  ),
  robots: {
    index: false,
    follow: false,
    googleBot: { index: false, follow: false, noimageindex: true },
  },
};

export default function BetaPage() {
  return (
    <main className="document-page" id="main-content" tabIndex={-1}>
      <header className="document-hero">
        <p className="section-kicker">FrameWink on TestFlight</p>
        <h1>Try the FrameWink beta.</h1>
        <p>
          Get early versions for iPhone and iPad, including iPhone Duo, and help
          make your private photo frame better.
        </p>
        <div className="support-actions">
          <a
            className="primary-action"
            href="https://testflight.apple.com/join/ZYutXJXW"
          >
            Join the beta
          </a>
          <a
            className="secondary-action"
            href="mailto:framewink@jenny.media?subject=FrameWink%20Beta%20Feedback"
          >
            Send feedback
          </a>
        </div>
        <p className="support-note">
          TestFlight will show whether a build is available and places are open.
        </p>
      </header>
      <article className="document-content">
        <section>
          <h2>How to join</h2>
          <p>
            Open this page on the iPhone or iPad you want to test. Choose Join the
            beta, install Apple&apos;s TestFlight app if prompted, then accept the
            invitation. FrameWink supports iOS and iPadOS 15 or later.
          </p>
        </section>
        <section>
          <h2>What to try</h2>
          <p>
            Choose a few photos, review your frame, then try swiping, pausing,
            rotating the screen, and changing Photo Duration. On iPhone Duo, open
            and fold the display and check that your current photo and paused
            state stay where you left them.
          </p>
        </section>
        <section>
          <h2>Tell us what happened</h2>
          <p>
            In FrameWink, choose More → Send Feedback. Include your device model,
            iOS or iPadOS version, and the steps we can follow to reproduce the
            issue. Please leave private photos out of your report.
          </p>
        </section>
      </article>
    </main>
  );
}
