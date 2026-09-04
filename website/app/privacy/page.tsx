import { pageMetadata } from "../siteMetadata";

export const metadata = pageMetadata(
  "Privacy Policy",
  "How FrameWink protects your photos and handles purchases and support.",
  "/privacy",
);

export default function PrivacyPage() {
  return (
    <main className="document-page" id="main-content" tabIndex={-1}>
      <header className="document-hero">
        <p className="section-kicker">Effective August 12, 2026</p>
        <h1>Privacy Policy</h1>
        <p>FrameWink is provided by Jenny Media LLC and is designed to keep your photo experience on your device.</p>
      </header>
      <article className="document-content">
        <section>
          <h2>The short version</h2>
          <p>
            FrameWink does not send your photos, app activity, device details, or purchase
            information to Jenny Media LLC. You do not need an account, and the app has no
            ads, tracking, or third-party analytics.
          </p>
        </section>
        <section>
          <h2>Photos</h2>
          <p>
            In the free version, Apple’s photo picker shares only the photos you choose. With
            FrameWink Lifetime, you can give FrameWink access to one album so new photos can
            appear automatically while the app is open. FrameWink shows album names and photo
            counts while you choose, then reads photos only from the album you select. It skips
            hidden photos and screenshots and never changes anything in your Photos library.
          </p>
          <p>
            If a photo you chose is stored in iCloud, Apple Photos may download it to your device
            before FrameWink can show it. FrameWink does not upload it or send it to Jenny Media LLC.
          </p>
        </section>
        <section>
          <h2>Local storage and deletion</h2>
          <p>
            FrameWink keeps screen-sized copies and the information it needs to choose, arrange,
            and rotate photos inside the app on your device. These copies and records are not
            included in device backups.
          </p>
          <p>
            <strong>Delete Imported Photos</strong> removes copies of photos you selected in the
            free version. <strong>Delete Automatic Album Cache</strong> removes local copies from
            the album you chose. Both also clear related app records without deleting or changing
            originals in Apple Photos. Removing FrameWink from your device removes its local data.
          </p>
        </section>
        <section>
          <h2>Purchases and Family Sharing</h2>
          <p>
            Apple handles FrameWink Lifetime purchases, restoring purchases, and Family Sharing.
            Jenny Media LLC never receives your payment-card details. Apple’s handling of purchase
            information is covered by <a href="https://www.apple.com/legal/privacy/">Apple’s Privacy Policy</a>.
          </p>
        </section>
        <section>
          <h2>This website</h2>
          <p>
            This website does not use analytics, ads, tracking, contact forms, or marketing cookies.
            Our hosting provider may process basic request information needed to load and protect the
            site under its own privacy terms. If you contact us by email or GitHub, those services
            handle your message under their own privacy terms.
          </p>
        </section>
        <section>
          <h2>Contact and support</h2>
          <p>
            For privacy questions or support, email <a href="mailto:framewink@jenny.media">framewink@jenny.media</a>
            {" "}or open a <a href="https://github.com/Jenny-Media/FrameWink/issues">FrameWink support issue</a>.
            GitHub issues are public, so please do not include private photos, purchase receipts, or sensitive
            personal information.
          </p>
        </section>
      </article>
    </main>
  );
}
