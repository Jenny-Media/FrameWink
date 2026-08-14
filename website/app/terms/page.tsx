import { pageMetadata } from "../siteMetadata";

export const metadata = pageMetadata(
  "Terms & Purchase Information",
  "FrameWink licensing, purchase, availability, and support information.",
  "/terms",
);

export default function TermsPage() {
  return (
    <main className="document-page" id="main-content" tabIndex={-1}>
      <header className="document-hero">
        <p className="section-kicker">Effective August 14, 2026</p>
        <h1>Terms &amp; Purchase Information</h1>
        <p>A concise explanation of how FrameWink is licensed and how its optional lifetime purchase works.</p>
      </header>
      <article className="document-content">
        <section>
          <h2>App license</h2>
          <p>
            FrameWink is licensed through Apple’s App Store, not sold. Unless a different agreement is
            presented with the app, use is governed by Apple’s
            {" "}<a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">Standard Licensed Application End User License Agreement</a>.
          </p>
        </section>
        <section>
          <h2>Free Smart Reel</h2>
          <p>
            The free experience includes bundled sample photos and one local Smart Reel created from up to
            500 selected photos, with up to 100 highlights. It has no watermark, advertisements,
            forced trial countdown, or subscription.
          </p>
        </section>
        <section>
          <h2>FrameWink Lifetime</h2>
          <p>
            FrameWink Lifetime is a $4.99 non-consumable in-app purchase in the United States.
            Local price and tax may differ by storefront. It unlocks paid features for the Apple Account
            recognized by StoreKit and supports Family Sharing where Apple makes that entitlement available.
          </p>
          <p>
            Purchase processing, refunds, restoration, and Family Sharing are provided by Apple. Use Restore
            Purchases inside FrameWink to ask StoreKit to refresh the current entitlement.
          </p>
        </section>
        <section>
          <h2>Availability and device behavior</h2>
          <p>
            Features depend on a compatible iPhone or iPad, the installed operating-system version, Photos
            authorization you choose to grant, and Apple services such as iCloud Photos and StoreKit. FrameWink
            cannot guarantee automatic relaunch after a restart or exact scheduled wake while the app is
            suspended or the device is locked.
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
