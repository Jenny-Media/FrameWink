import Image from "next/image";
import { appStoreURL } from "./siteMetadata";

/* eslint-disable jsx-a11y/no-redundant-roles -- Explicit list roles preserve Safari and VoiceOver semantics after list markers are removed. */

const privacyPoints = ["No account", "No tracking", "Your photos stay private"];

const imagePlaceholder =
  "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20width='32'%20height='32'%3E%3Crect%20width='32'%20height='32'%20fill='%23e8e0d0'/%3E%3C/svg%3E";

const features = [
  {
    number: "01",
    title: "Your best photos",
    body: "FrameWink creates a varied mix from the photos you choose, without showing the same moments over and over.",
  },
  {
    number: "02",
    title: "Everyone stays in the picture",
    body: "Faces and important details stay in view, whether one photo fills the screen or several share it.",
  },
  {
    number: "03",
    title: "A frame that feels alive",
    body: "Gentle fades, pans, and zooms keep the frame feeling alive without asking for your attention. If you prefer less motion, FrameWink respects that.",
  },
];

const steps = [
  { symbol: "+", title: "Choose", body: "Pick the photos you want to see—and nothing else." },
  { symbol: "✓", title: "Review", body: "Preview the reel and remove any photo you don’t want displayed from it." },
  { symbol: "▶", title: "Enjoy", body: "Start the frame, swipe when you want, and let your photos change quietly." },
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
    "FrameWink Lifetime lets you build a frame from one Apple Photos album you choose, without the 500-photo limit. While FrameWink is open, it keeps the reel fresh as the album changes, avoids recent repeats for longer, adds more arrangements, and lets you schedule the display to dim or go dark at night. It also includes help for setting up a mounted iPad.",
  ],
];

const structuredData = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "FrameWink",
  applicationCategory: "MultimediaApplication",
  operatingSystem: "iOS 15 or later; iPadOS 15 or later",
  description:
    "Turn an iPad or iPhone into a calm, private photo frame. FrameWink never uploads your photos.",
  url: "https://frame.jenny.media",
  installUrl: appStoreURL,
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
          <p className="eyebrow">Your best digital frame may already be in your drawer</p>
          <h1 id="hero-title">Your photos. Beautifully framed.</h1>
          <p className="hero-lede">
            Turn an iPad you already own into a calm, private photo frame. Choose
            the moments you love, decide what appears, and enjoy them throughout
            your day. FrameWink never uploads your photos.
          </p>
          <div className="hero-actions">
            <a
              className="app-store-badge-link"
              href={appStoreURL}
              aria-label="Download FrameWink on the App Store"
            >
              <Image
                src="/images/download-on-the-app-store.svg"
                alt="Download on the App Store"
                width={359}
                height={120}
                preload
              />
            </a>
            <a className="hero-explore-link" href="#features">
              <span>See how it works</span>
              <span className="hero-explore-icon" aria-hidden="true">
                <svg viewBox="0 0 20 20" fill="none">
                  <path
                    d="M10 3.75v10.5m0 0 4-4m-4 4-4-4"
                    stroke="currentColor"
                    strokeWidth="1.8"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </span>
            </a>
            <p>Free to download · Optional one-time upgrade</p>
          </div>
          <ul className="trust-list" aria-label="FrameWink privacy highlights" role="list">
            {privacyPoints.map((point) => <li key={point} role="listitem">{point}</li>)}
          </ul>
        </div>

        <div className="hero-visual">
          <figure className="flat-device-stage">
            <div className="flat-device-cycle">
              <Image
                className="flat-device-image flat-device-primary"
                src="/images/ipad-flat-frame-v1.webp"
                alt="FrameWink displaying a clean single-photo frame inside an iPad bezel"
                width={1500}
                height={1150}
                sizes="(max-width: 1180px) 100vw, 58vw"
                preload
              />
              <Image
                className="flat-device-image flat-device-secondary"
                src="/images/ipad-flat-mosaic-v1.webp"
                alt=""
                aria-hidden="true"
                width={1500}
                height={1150}
                sizes="(max-width: 1180px) 100vw, 58vw"
              />
            </div>
            <figcaption>Actual FrameWink screens</figcaption>
          </figure>
        </div>
      </section>

      <section className="privacy-strip" aria-labelledby="privacy-heading">
        <p className="section-kicker">Private by design</p>
        <h2 id="privacy-heading">Your photos stay yours.</h2>
        <p className="privacy-summary">
          FrameWink never uploads your photos. Choosing, arranging, and displaying
          happen on your device, with no account, ads, or tracking. If you choose
          an automatic album, Apple Photos may download an iCloud photo to your device.
        </p>
        <a className="text-link light" href="/privacy">Read the privacy policy <span aria-hidden="true">↗</span></a>
      </section>

      <section className="feature-section content-section" id="features" aria-labelledby="features-heading" tabIndex={-1}>
        <div className="section-heading split-heading">
          <div>
            <p className="section-kicker">Less setup. Better viewing.</p>
            <h2 id="features-heading">Beautiful by default.</h2>
          </div>
          <p>
            Your photos arrive beautifully arranged, without complicated setup.
            You stay in control of what appears.
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

      <section className="showcase" id="ipad" aria-labelledby="showcase-heading">
        <div className="showcase-copy">
          <p className="section-kicker">iPad-first by design</p>
          <h2 id="showcase-heading">Made for the places you love.</h2>
          <p>
            Set an iPad on a shelf, desk, or wall and let the moments you love
            become part of the room. FrameWink adapts the view as your screen changes.
          </p>
          <CheckList items={[
            "One favorite photo or a thoughtful mix",
            "Beautiful arrangements that fit your screen",
            "Controls stay out of the way until you need them",
          ]} />
        </div>
        <figure className="flat-showcase-device">
          <Image
            src="/images/ipad-flat-pair-v2.webp"
            alt="FrameWink showing two compatible portrait photos side by side inside an iPad bezel"
            width={1500}
            height={1150}
            sizes="(max-width: 900px) 92vw, 54vw"
            placeholder="blur"
            blurDataURL={imagePlaceholder}
          />
          <figcaption>When they fit well, portrait photos sit side by side automatically.</figcaption>
        </figure>
      </section>

      <section className="iphone-note content-section" id="iphone" aria-labelledby="iphone-heading">
        <div className="iphone-note-copy">
          <h2 id="iphone-heading">A private photo frame in your pocket.</h2>
          <p>FrameWink works on iPhone too, with the same private reel adapted for a smaller screen.</p>
        </div>
        <div className="iphone-mini-preview" aria-hidden="true">
          <Image
            src="/images/iphone-cyclist-demo.webp"
            alt=""
            width={240}
            height={520}
            sizes="120px"
          />
        </div>
      </section>

      <section className="steps-section content-section" id="how-it-works" aria-labelledby="steps-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Simple from the start</p>
          <h2 id="steps-heading">From your photos to a frame in a few taps.</h2>
        </div>
        <ol className="steps-grid" role="list">
          {steps.map(({ symbol, title, body }) => (
            <li key={title} role="listitem">
              <span className="step-symbol" aria-hidden="true">{symbol}</span>
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
              "Thoughtfully curated on your device",
              "Review and Never Show Again",
              "Beautiful arrangements, gentle motion, and unlimited replay",
            ]} />
          </article>
          <article className="plan-card lifetime-plan">
            <div>
              <h3 className="plan-label">FrameWink Lifetime</h3>
              <p className="price">$4.99 <small>once in the U.S.</small></p>
              <p>Keep one Apple Photos album refreshed while FrameWink remains open. Local App Store price may vary.</p>
            </div>
            <CheckList items={[
              "One Apple Photos album, with no 500-photo limit",
              "New album photos appear automatically, with fewer recent repeats",
              "Set the frame to dim or go dark at night while the app is open",
              "More arrangements and help setting up a mounted iPad",
              "Family Sharing where supported by Apple",
            ]} />
          </article>
        </div>
      </section>

      <section className="review-callout" id="availability" aria-labelledby="availability-heading" tabIndex={-1}>
        <Image src="/images/framewink-icon.png" alt="FrameWink app icon" width={120} height={120} />
        <div>
          <p className="section-kicker">Available on the App Store</p>
          <h2 id="availability-heading">Give your iPhone or iPad a new purpose.</h2>
          <p>Download FrameWink from the App Store. Requires iOS or iPadOS 15 or later.</p>
        </div>
        <a
          className="secondary-action"
          href={appStoreURL}
        >
          View on the App Store
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
