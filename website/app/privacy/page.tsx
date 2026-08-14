import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "How FrameWink handles photos, local app data, purchases, and website requests.",
};

export default function PrivacyPage() {
  return (
    <main className="document-page" id="main-content">
      <header className="document-hero">
        <p className="section-kicker">Effective August 12, 2026</p>
        <h1>Privacy Policy</h1>
        <p>FrameWink is provided by Jenny Media LLC and is designed to keep your photo experience on your device.</p>
      </header>
      <article className="document-content">
        <section>
          <h2>The short version</h2>
          <p>
            The FrameWink app has no Jenny Media LLC account or server and does not upload photos,
            app activity, identifiers, diagnostics, purchases, or other personal data to Jenny Media LLC.
            It does not use advertising, tracking, or third-party analytics SDKs.
          </p>
        </section>
        <section>
          <h2>Photos</h2>
          <p>
            Apple’s system photo picker gives FrameWink only the free-mode photos you choose. After a
            FrameWink Lifetime purchase, you may explicitly authorize Photos and select an album for
            automatic refresh. FrameWink lists album names and photo counts for that chooser, reads photo
            content only from the selected album, filters hidden photos and screenshots, and never edits
            your Photos library.
          </p>
          <p>
            Apple Photos may download an iCloud item when an automatic album needs it. That is Apple Photos
            behavior, not a FrameWink upload or a connection to Jenny Media LLC.
          </p>
        </section>
        <section>
          <h2>Local storage and deletion</h2>
          <p>
            FrameWink stores display-sized copies, local curation records, and local display history in its
            private app container. Photo copies, automatic-album cache data, and derived curation data are
            excluded from device backup.
          </p>
          <p>
            <strong>Delete Imported Photos</strong> and <strong>Delete Automatic Album Cache</strong> remove
            corresponding app-controlled copies and derived records without deleting or changing originals
            in Apple Photos. Removing the app also removes its private local container through normal iOS or
            iPadOS behavior.
          </p>
        </section>
        <section>
          <h2>Purchases and Family Sharing</h2>
          <p>
            FrameWink Lifetime purchases, restoration, and Family Sharing use Apple’s StoreKit and App Store
            services. Jenny Media LLC does not receive payment-card details through FrameWink. Apple’s
            processing is governed by <a href="https://www.apple.com/legal/privacy/">Apple’s Privacy Policy</a>.
          </p>
        </section>
        <section>
          <h2>This website</h2>
          <p>
            This static website does not use product analytics, advertising pixels, tracking scripts, contact
            forms, or marketing cookies. Its hosting provider may process ordinary request information needed
            to deliver and secure the site under its own privacy terms. Email and GitHub support are separate
            services you choose to use.
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
