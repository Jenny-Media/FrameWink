import Image from "next/image";

const privacyPoints = ["No account", "No tracking", "On-device curation"];

const features = [
  {
    number: "01",
    title: "A smarter reel",
    body: "FrameWink reviews the photos you choose, reduces near-duplicates, and prepares a varied reel without sending your library anywhere.",
  },
  {
    number: "02",
    title: "Cropping with care",
    body: "Face- and subject-aware framing chooses when to fill the screen, when to fit the whole photo, and when a multi-photo layout genuinely works.",
  },
  {
    number: "03",
    title: "Quietly alive",
    body: "Restrained fades, slow zooms, and gentle pans add life without becoming a distraction—and Reduce Motion is always respected.",
  },
];

const steps = [
  ["Choose", "Pick a few favorites with Apple’s system photo picker. Full-library access is not required."],
  ["Review", "FrameWink prepares local recommendations you can review before anything reaches the frame."],
  ["Enjoy", "Start the frame, swipe naturally, pause anytime, or share the photo currently in view."],
];

export default function Home() {
  return (
    <main id="main-content">
      <section className="hero" aria-labelledby="hero-title">
        <div className="hero-copy">
          <p className="eyebrow">Your photos. Your frame. Your device.</p>
          <h1 id="hero-title">Beautiful memories, quietly in motion.</h1>
          <p className="hero-lede">
            FrameWink turns an iPhone or iPad into a private, intelligent photo
            frame—curated on your device from photos you choose.
          </p>
          <div className="hero-actions">
            <a className="primary-action" href="#features">
              Explore FrameWink <span aria-hidden="true">↓</span>
            </a>
            <p>Free Smart Reel · Optional $9.99 lifetime Wall Mode</p>
          </div>
          <ul className="trust-list" aria-label="FrameWink privacy highlights">
            {privacyPoints.map((point) => <li key={point}>{point}</li>)}
          </ul>
        </div>

        <div className="hero-visual">
          <div className="sun-orbit" aria-hidden="true" />
          <div className="device ipad">
            <div className="device-camera" aria-hidden="true" />
            <Image
              src="/images/framewink-mosaic-ipad.jpg"
              alt="FrameWink showing an automatic four-photo layout on an iPad"
              width={1200}
              height={1600}
              sizes="(max-width: 900px) 80vw, 40vw"
              priority
            />
          </div>
          <div className="icon-card" aria-hidden="true">
            <Image src="/images/framewink-icon.png" alt="" width={96} height={96} />
            <span>Made for iPhone &amp; iPad</span>
          </div>
        </div>
      </section>

      <section className="privacy-strip" aria-labelledby="privacy-heading">
        <p className="section-kicker">Private by design</p>
        <h2 id="privacy-heading">The cloud doesn’t need your memories.</h2>
        <p>
          Photo selection, analysis, curation, and display stay on your device.
          FrameWink has no account, developer server, analytics, ads, or tracking.
        </p>
        <a className="text-link light" href="/privacy">Read the privacy policy <span aria-hidden="true">↗</span></a>
      </section>

      <section className="feature-section content-section" id="features" aria-labelledby="features-heading">
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
          <p className="section-kicker">Made for every orientation</p>
          <h2 id="showcase-heading">One frame that understands the space it has.</h2>
          <p>
            A compact iPhone gets one clear focal image. A larger iPad can pair
            portraits or build a calm mosaic. Resize an iPad window and the scene
            adapts instead of leaving awkward empty space.
          </p>
          <ul className="check-list">
            <li>Face-safe Fit and Fill decisions</li>
            <li>Automatic portrait pairing and mosaics</li>
            <li>Swipe, pause, share, and adjustable timing</li>
          </ul>
        </div>
        <div className="showcase-gallery">
          <figure className="shot shot-tall">
            <Image
              src="/images/frame-iphone.jpg"
              alt="FrameWink showing a photo in full-screen frame mode on iPhone"
              width={737}
              height={1600}
              sizes="(max-width: 760px) 55vw, 25vw"
            />
          </figure>
          <figure className="shot shot-wide">
            <Image
              src="/images/review-ipad.jpg"
              alt="FrameWink review suggestions grid on iPad"
              width={1200}
              height={1600}
              sizes="(max-width: 760px) 70vw, 34vw"
            />
          </figure>
        </div>
      </section>

      <section className="steps-section content-section" aria-labelledby="steps-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Three simple moments</p>
          <h2 id="steps-heading">From camera roll to frame in minutes.</h2>
        </div>
        <ol className="steps-grid">
          {steps.map(([title, body], index) => (
            <li key={title}>
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
              <p className="plan-label">Free Smart Reel</p>
              <p className="price">$0</p>
              <p>Import up to 500 candidates and keep one local reel with up to 100 recommendations.</p>
            </div>
            <ul className="check-list">
              <li>Full-quality local curation</li>
              <li>Review and Never Show Again</li>
              <li>Automatic layouts, motion, and replay</li>
            </ul>
          </article>
          <article className="plan-card lifetime-plan">
            <div>
              <p className="plan-label">FrameWink Lifetime</p>
              <p className="price">$9.99 <small>once</small></p>
              <p>Turn a chosen Photos album into a dependable, continuously refreshed frame.</p>
            </div>
            <ul className="check-list">
              <li>Unlimited supported candidates and albums</li>
              <li>Automatic album refresh and repeat avoidance</li>
              <li>Schedules, extra layouts, and mounted-display guidance</li>
              <li>Family Sharing where supported by Apple</li>
            </ul>
          </article>
        </div>
      </section>

      <section className="review-callout" aria-labelledby="availability-heading">
        <Image src="/images/framewink-icon.png" alt="FrameWink app icon" width={120} height={120} />
        <div>
          <p className="section-kicker">Coming to the App Store</p>
          <h2 id="availability-heading">FrameWink 1.0 is in App Review.</h2>
          <p>Built for iPhone and iPad running iOS or iPadOS 15 and later.</p>
        </div>
        <a className="secondary-action" href="mailto:framewink@jenny.media?subject=FrameWink%20launch">
          Ask about launch
        </a>
      </section>

      <section className="faq-section content-section" aria-labelledby="faq-heading">
        <div className="section-heading centered-heading">
          <p className="section-kicker">Good to know</p>
          <h2 id="faq-heading">A few clear answers.</h2>
        </div>
        <div className="faq-list">
          <details>
            <summary>Does FrameWink upload my photos?</summary>
            <p>No. Jenny Media LLC has no FrameWink photo server. Selection, analysis, curation, and display happen on your device. Apple Photos may download an iCloud item when you ask FrameWink to use an automatic album.</p>
          </details>
          <details>
            <summary>Do I need to give access to my whole library?</summary>
            <p>No. The free Smart Reel uses Apple’s system picker and receives only the photos you select. Full Photos access is requested only if you explicitly enable a paid automatic album.</p>
          </details>
          <details>
            <summary>Can FrameWink change or delete originals?</summary>
            <p>No. FrameWink never edits, deletes, favorites, hides, or otherwise changes your Apple Photos library.</p>
          </details>
          <details>
            <summary>Does it support Mac or Apple Vision Pro?</summary>
            <p>The first release supports iPhone and iPad only. Mac, Mac Catalyst, and Apple Vision Pro availability are disabled.</p>
          </details>
        </div>
      </section>
    </main>
  );
}
