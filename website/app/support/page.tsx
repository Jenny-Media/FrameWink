import { pageMetadata } from "../siteMetadata";

export const metadata = pageMetadata(
  "Support",
  "Get help with FrameWink setup, Photos access, purchases, and playback.",
  "/support",
);

const helpItems = [
  ["The album chooser looks empty or slow", "Keep FrameWink open while covers load progressively. An iCloud-only cover may need Apple Photos to download it. Close and reopen the chooser to reuse the local cover cache."],
  ["A photo is cropped unexpectedly", "FrameWink automatically chooses Fit or Fill from the screen shape and important content. Resize the window or swipe away and back after the scene changes. If a suggestion should never return, use Never Show Again during review."],
  ["Restore FrameWink Lifetime", "Open the FrameWink Lifetime screen and choose Restore Purchases while signed into the Apple Account that made or shares the purchase."],
  ["Remove imported photos", "Open FrameWink settings and choose Delete Imported Photos. This removes FrameWink’s local copies and curation records without touching originals in Apple Photos."],
];

const productQuestions = [
  ["Can family members send photos to the frame remotely?", "No. FrameWink has no remote upload or administration service. Family Sharing can share the purchase entitlement, but it does not send photos between devices."],
  ["Does FrameWink play videos or Live Photo motion?", "Not in the first release. FrameWink displays still photos and does not play videos or Live Photo motion."],
  ["Can FrameWink change or delete originals?", "No. FrameWink never edits, deletes, favorites, hides, or otherwise changes your Apple Photos library."],
  ["Does it support Mac or Apple Vision Pro?", "The first release supports iPhone and iPad only. Mac, Mac Catalyst, and Apple Vision Pro availability are disabled."],
];

export default function SupportPage() {
  return (
    <main className="document-page support-page" id="main-content" tabIndex={-1}>
      <header className="document-hero support-hero">
        <p className="section-kicker">We’re here to help</p>
        <h1>FrameWink Support</h1>
        <p>Start with the quick answers below, or contact Jenny Media directly.</p>
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
          <h2>iPhone and iPad only.</h2>
        </div>
        <p>FrameWink requires iOS or iPadOS 15 or later. Mac, Mac Catalyst, Apple Vision Pro, Android, and web playback are not supported in the first release.</p>
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
