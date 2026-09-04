import { pageMetadata } from "../siteMetadata";

export const metadata = pageMetadata(
  "Terms & Purchase Information",
  "What comes with FrameWink, what Lifetime adds, and how Apple handles your purchase.",
  "/terms",
);

export default function TermsPage() {
  return (
    <main className="document-page" id="main-content" tabIndex={-1}>
      <header className="document-hero">
        <p className="section-kicker">Effective August 14, 2026</p>
        <h1>Terms &amp; Purchase Information</h1>
        <p>Here’s what comes with FrameWink and how the optional Lifetime purchase works.</p>
      </header>
      <article className="document-content">
        <section>
          <h2>App license</h2>
          <p>
            When you download FrameWink, Apple gives you a license to use it; you do not own the
            app itself. Unless FrameWink shows a different agreement, Apple’s
            {" "}<a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Standard Licensed Application End User License Agreement</a>
            {" "}applies.
          </p>
        </section>
        <section>
          <h2>Free Smart Reel</h2>
          <p>
            The free version includes sample photos and one Smart Reel made from up to 500 photos
            you choose, with up to 100 highlights. There is no watermark, advertising, trial
            countdown, or subscription.
          </p>
        </section>
        <section>
          <h2>FrameWink Lifetime</h2>
          <p>
            FrameWink Lifetime is a $4.99 one-time in-app purchase in the United States. Price and
            tax may vary in other App Store regions. It unlocks the paid features for the Apple
            Account used to buy it and can be shared with family when Apple supports Family Sharing.
          </p>
          <p>
            Apple handles payment, refunds, restoring purchases, and Family Sharing. If Lifetime
            does not appear after you reinstall FrameWink or change devices, choose Restore Purchases
            inside the app.
          </p>
        </section>
        <section>
          <h2>Availability and device behavior</h2>
          <p>
            FrameWink works on compatible iPhones and iPads. Some features need access to the photos
            you choose, and photos stored in iCloud may need to download first. Schedules work only
            while FrameWink is open, and the app cannot reopen itself after your device restarts.
          </p>
        </section>
        <section>
          <h2>Contact</h2>
          <p>
            Questions about these terms or a FrameWink purchase can be sent to
            {" "}<a href="mailto:framewink@jenny.media">framewink@jenny.media</a>.
          </p>
        </section>
      </article>
    </main>
  );
}
