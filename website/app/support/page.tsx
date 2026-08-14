import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Support",
  description: "Get help with FrameWink setup, Photos access, purchases, and playback.",
};

const helpItems = [
  ["The album chooser looks empty or slow", "Keep FrameWink open while covers load progressively. An iCloud-only cover may need Apple Photos to download it. Close and reopen the chooser to reuse the local cover cache."],
  ["A photo is cropped unexpectedly", "FrameWink automatically chooses Fit or Fill from the screen shape and important content. Resize the window or swipe away and back after the scene changes. If a suggestion should never return, use Never Show Again during review."],
  ["Restore FrameWink Lifetime", "Open the FrameWink Lifetime screen and choose Restore Purchases while signed into the Apple Account that made or shares the purchase."],
  ["Remove imported photos", "Open FrameWink settings and choose Delete Imported Photos. This removes FrameWink’s local copies and curation records without touching originals in Apple Photos."],
];

export default function SupportPage() {
  return (
    <main className="document-page support-page" id="main-content">
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
    </main>
  );
}
