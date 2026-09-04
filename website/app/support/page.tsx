import { pageMetadata } from "../siteMetadata";

export const metadata = pageMetadata(
  "Support",
  "Get help choosing photos, using albums, restoring a purchase, and enjoying your frame.",
  "/support",
);

const helpItems = [
  ["Album covers are missing or slow to appear", "Album covers may take a moment to appear, especially for photos stored in iCloud. Keep FrameWink open. If a cover still does not appear, close and reopen the album list."],
  ["A photo is cropped unexpectedly", "FrameWink fits each photo to the screen while trying to keep faces and important details visible. Turn or resize the screen, then swipe away and back to refresh the view. To keep a photo out of the frame, choose Never Show Again while reviewing."],
  ["Restore FrameWink Lifetime", "Go to FrameWink Lifetime and choose Restore Purchases. Make sure the device uses the Apple Account that bought or shares the purchase."],
  ["Remove imported photos", "Open FrameWink settings and choose Delete Imported Photos. This removes copies saved inside FrameWink without touching the originals in Apple Photos."],
];

const productQuestions = [
  ["Can family members send photos to the frame remotely?", "No. FrameWink does not send photos between devices. Family Sharing can share the Lifetime purchase with eligible family members, but each person chooses photos on their own device."],
  ["Does FrameWink play videos or Live Photo motion?", "FrameWink shows still photos only. Videos and Live Photo motion are not currently supported."],
  ["Can FrameWink change or delete originals?", "No. FrameWink never edits, deletes, favorites, hides, or otherwise changes your Apple Photos library."],
  ["Does it work on Mac or Apple Vision Pro?", "No. FrameWink is currently available for iPhone and iPad."],
];

export default function SupportPage() {
  return (
    <main className="document-page support-page" id="main-content" tabIndex={-1}>
      <header className="document-hero support-hero">
        <p className="section-kicker">We’re here to help</p>
        <h1>FrameWink Support</h1>
        <p>Start with the quick answers below, or contact us directly.</p>
        <div className="support-actions">
          <a className="primary-action" href="mailto:framewink@jenny.media?subject=FrameWink%20Support">Email support</a>
          <a className="secondary-action" href="https://github.com/Jenny-Media/FrameWink/issues/new">Open a public issue</a>
        </div>
        <p className="support-note">Please don’t attach private photos, receipts, or personal information to a public GitHub issue.</p>
      </header>
      <section className="help-grid" aria-labelledby="quick-help-heading">
        <h2 id="quick-help-heading">Quick help</h2>
        <div>
          {helpItems.map(([title, body]) => (
            <article key={title}>
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="system-requirements">
        <div>
          <p className="section-kicker">Compatibility</p>
          <h2>Made for iPhone and iPad.</h2>
        </div>
        <p>FrameWink works with iPhone and iPad running iOS or iPadOS 15 or later. It is not currently available for Mac, Apple Vision Pro, Android, or the web.</p>
      </section>
      <section className="faq-section support-faq" aria-labelledby="support-faq-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">More answers</p>
          <h2 id="support-faq-heading">Product questions.</h2>
        </div>
        <div className="faq-list">
          {productQuestions.map(([question, answer]) => (
            <details key={question}>
              <summary>
                {question}
                <span className="faq-icon" aria-hidden="true" />
              </summary>
              <p>{answer}</p>
            </details>
          ))}
        </div>
      </section>
    </main>
  );
}
