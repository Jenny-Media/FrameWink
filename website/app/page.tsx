import Image from "next/image";

/* eslint-disable jsx-a11y/no-redundant-roles -- Explicit list roles preserve Safari and VoiceOver semantics after list markers are removed. */

const privacyPoints = ["No account", "No tracking", "On-device curation"];

const imagePlaceholder =
  "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20width='32'%20height='32'%3E%3Crect%20width='32'%20height='32'%20fill='%23e8e0d0'/%3E%3C/svg%3E";

const features = [
  {
    number: "01",
    title: "A smarter reel",
    body: "FrameWink reviews the photos you choose, reduces near-duplicates, and prepares a varied reel without sending your library anywhere.",
  },
  {
    number: "02",
    title: "Cropping with care",
    body: "Face- and content-aware framing chooses when to fill the screen, when to fit the whole photo, and when a multi-photo layout genuinely works.",
  },
  {
    number: "03",
    title: "Quietly alive",
    body: "Restrained fades, slow zooms, and gentle pans add life without becoming a distraction—and Reduce Motion is always respected.",
  },
];

const steps = [
  ["Choose", "Pick a few favorites with Apple’s system photo picker. Full-library access is not required."],
  ["Review", "FrameWink prepares local highlights you can review before anything reaches the frame."],
  ["Enjoy", "Start the frame, swipe naturally, pause anytime, or share the photo currently in view."],
];

const faqItems = [
  [
    "Does the free version expire?",
    "No. Free Smart Reel has no countdown. You can import up to 500 photos, keep one reel with up to 100 highlights, and replay it as often as you like.",
  ],
  [
    "Does FrameWink upload my photos?",
    "No. Jenny Media LLC has no FrameWink photo server. Selection, analysis, curation, and display happen on your device. Apple Photos may download an iCloud item when you ask FrameWink to use an automatic album.",
  ],
  [
    "Do I need to give access to my whole library?",
    "No. Free Smart Reel uses Apple’s system picker and receives only the photos you select. Full Photos access is requested only if you explicitly enable a paid automatic album.",
  ],
  [
    "What does FrameWink Lifetime add?",
    "The one-time upgrade can use every eligible photo from one supported Photos album you choose, refreshes that album while FrameWink is open, avoids recent repeats for longer, and adds visual night schedules while the app is open, more automatic layouts, and mounted-display guidance.",
  ],
];

const structuredData = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "FrameWink",
  applicationCategory: "MultimediaApplication",
  operatingSystem: "iOS 15 or later; iPadOS 15 or later",
  description:
    "A private smart photo frame for iPhone and iPad, curated on your device from photos you choose.",
  offers: [
    { "@type": "Offer", name: "Free Smart Reel", price: "0", priceCurrency: "USD" },
    { "@type": "Offer", name: "FrameWink Lifetime", price: "4.99", priceCurrency: "USD" },
  ],
};

function CheckList({ items }: { items: readonly string[] }) {
  return (
    <ul className="check-list" role="list">
      {items.map((item) => (
        <li key={item} role="listitem">
          <span className="check-mark" aria-hidden="true" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

export default function Home() {
  return (
    <main id="main-content" tabIndex={-1}>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
      />
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow">Made for iPad. Ready for iPhone.</p>
          <h1 id="hero-title">Turn your iPad into a private photo frame.</h1>
          <p className="hero-lede">
            FrameWink turns the screen you already own into a calm, intelligent
            frame—curated privately on your device from photos you choose.
            It works beautifully on iPhone too.
          </p>
          <div className="hero-actions">
            <a className="primary-action" href="#features">
              Explore FrameWink <span aria-hidden="true">↓</span>
            </a>
            <a
              className="launch-action"
              href="mailto:framewink@jenny.media?subject=FrameWink%20launch&amp;body=Please%20let%20me%20know%20when%20FrameWink%20is%20available%20on%20the%20App%20Store."
            >
              Email me at launch
            </a>
            <p>Free Smart Reel · Optional $4.99 lifetime upgrade</p>
          </div>
          <ul className="trust-list" aria-label="FrameWink privacy highlights" role="list">
            {privacyPoints.map((point) => <li key={point} role="listitem">{point}</li>)}
          </ul>
        </div>

        <div className="hero-visual">
          <figure className="hero-capture">
            <Image
              src="/images/ipad-landscape-frame.webp"
              alt="Native FrameWink frame view captured in landscape on iPad"
              width={1600}
              height={1200}
              sizes="(max-width: 900px) 100vw, 58vw"
              preload
            />
            <figcaption>
              <span>Actual in-app screen</span>
              <strong>FrameWink running in landscape on iPad.</strong>
            </figcaption>
          </figure>
        </div>
      </section>

      <section className="privacy-strip" aria-labelledby="privacy-heading">
        <p className="section-kicker">Private by design</p>
        <h2 id="privacy-heading">No second photo cloud.</h2>
        <p>
          Photo selection, analysis, curation, and display stay on your device.
          FrameWink has no account or photo server, analytics, ads, or tracking.
          Apple Photos can still download an iCloud photo you choose.
        </p>
        <a className="text-link light" href="/privacy">Read the privacy policy <span aria-hidden="true">↗</span></a>
      </section>

      <section className="feature-section content-section" id="features" aria-labelledby="features-heading" tabIndex={-1}>
        <div className="section-heading split-heading">
          <div>
            <p className="section-kicker">Less setup. Better viewing.</p>
            <h2 id="features-heading">Your frame makes the decisions that should feel automatic.</h2>
          </div>
          <p>
            FrameWink favors a few excellent defaults over a wall of settings.
            Choose photos, review the reel, and let the current screen shape guide the presentation.
          </p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.number}>
              <span>{feature.number}</span>
              <h3>{feature.title}</h3>
              <p>{feature.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="showcase" aria-labelledby="showcase-heading">
        <div className="showcase-copy">
          <p className="section-kicker">iPad-first by design</p>
          <h2 id="showcase-heading">Made for the places your memories belong.</h2>
          <p>
            Set an iPad on a shelf, place it on a desk, or prepare it for a
            mounted display. FrameWink uses the larger canvas for calm,
            automatic compositions without turning setup into a project.
          </p>
          <CheckList items={[
            "Landscape single-photo and multi-photo scenes",
            "Layouts that adapt to the current screen shape",
            "Controls that recede when you return to the moment",
          ]} />
        </div>
        <div className="landscape-gallery">
          <figure className="landscape-shot landscape-shot-main">
            <Image
              src="/images/ipad-landscape-mosaic.webp"
              alt="Native FrameWink iPad capture arranging four photos automatically"
              width={1600}
              height={1200}
              sizes="(max-width: 900px) 92vw, 49vw"
              placeholder="blur"
              blurDataURL={imagePlaceholder}
            />
            <figcaption>Automatic layouts use the full iPad canvas.</figcaption>
          </figure>
          <figure className="landscape-shot landscape-shot-secondary">
            <Image
              src="/images/ipad-landscape-controls.webp"
              alt="Native FrameWink iPad capture with photo-duration controls visible"
              width={1600}
              height={1200}
              sizes="(max-width: 900px) 76vw, 30vw"
              placeholder="blur"
              blurDataURL={imagePlaceholder}
            />
            <figcaption>Adjust timing, then let the controls disappear.</figcaption>
          </figure>
        </div>
      </section>

      <section className="iphone-companion content-section" aria-labelledby="iphone-heading">
        <figure>
          <Image
            src="/images/iphone-landscape-frame.webp"
            alt="Native FrameWink capture showing a photo in landscape on iPhone"
            width={1600}
            height={736}
            sizes="(max-width: 760px) 92vw, 46vw"
            placeholder="blur"
            blurDataURL={imagePlaceholder}
          />
          <figcaption>Actual in-app screen · FrameWink in landscape on iPhone.</figcaption>
        </figure>
        <div>
          <p className="section-kicker">Works on iPhone too</p>
          <h2 id="iphone-heading">A smaller frame for wherever you are.</h2>
          <p>
            The same private reel, careful framing, natural swipe navigation,
            and direct sharing fit the iPhone in your pocket or on your desk.
          </p>
        </div>
      </section>

      <section className="steps-section content-section" aria-labelledby="steps-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Three simple moments</p>
          <h2 id="steps-heading">From camera roll to frame in minutes.</h2>
        </div>
        <ol className="steps-grid" role="list">
          {steps.map(([title, body], index) => (
            <li key={title} role="listitem">
              <span>{index + 1}</span>
              <h3>{title}</h3>
              <p>{body}</p>
            </li>
          ))}
        </ol>
      </section>

      <section className="plans-section" aria-labelledby="plans-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Useful before you pay</p>
          <h2 id="plans-heading">Start free. Upgrade once.</h2>
          <p>No subscription, countdown, advertising, or watermark.</p>
        </div>
        <div className="plan-grid">
          <article className="plan-card free-plan">
            <div>
              <h3 className="plan-label">Free Smart Reel</h3>
              <p className="price">$0</p>
              <p>Choose up to 500 photos and keep one local reel with up to 100 highlights.</p>
            </div>
            <CheckList items={[
              "Full-quality local curation",
              "Review and Never Show Again",
              "Automatic layouts, motion, and replay",
            ]} />
          </article>
          <article className="plan-card lifetime-plan">
            <div>
              <h3 className="plan-label">FrameWink Lifetime</h3>
              <p className="price">$4.99 <small>once</small></p>
              <p>Keep the Photos album you choose refreshed while FrameWink remains open.</p>
            </div>
            <CheckList items={[
              "Use one supported Photos album without the free 500-photo cap",
              "Automatic refresh and longer repeat avoidance",
              "Visual night schedules while FrameWink is open",
              "Extra layouts and mounted-display guidance",
              "Family Sharing where supported by Apple",
            ]} />
          </article>
        </div>
      </section>

      <section className="review-callout" id="availability" aria-labelledby="availability-heading" tabIndex={-1}>
        <Image src="/images/framewink-icon.png" alt="FrameWink app icon" width={120} height={120} />
        <div>
          <p className="section-kicker">Coming to the App Store</p>
          <h2 id="availability-heading">FrameWink 1.0 is in App Review.</h2>
          <p>Built for iPhone and iPad only, running iOS or iPadOS 15 and later.</p>
        </div>
        <a
          className="secondary-action"
          href="mailto:framewink@jenny.media?subject=FrameWink%20launch&amp;body=Please%20let%20me%20know%20when%20FrameWink%20is%20available%20on%20the%20App%20Store."
        >
          Email me when it launches
        </a>
      </section>

      <section className="faq-section content-section" aria-labelledby="faq-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Good to know</p>
          <h2 id="faq-heading">A few clear answers.</h2>
        </div>
        <div className="faq-list">
          {faqItems.map(([question, answer]) => (
            <details key={question}>
              <summary>
                {question}
                <span className="faq-icon" aria-hidden="true" />
              </summary>
              <p>{answer}</p>
            </details>
          ))}
        </div>
        <p className="faq-more">
          <a className="text-link" href="/support">See more answers and support <span aria-hidden="true">→</span></a>
        </p>
      </section>
    </main>
  );
}
