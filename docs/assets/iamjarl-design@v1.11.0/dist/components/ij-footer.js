// IAMJARL <ij-footer> v1.11.0 — generated, do not edit
// Sources: components/select-links.js, components/ij-footer.js, apps.json

const REGISTRY = {
  "$comment": "Canonical list of IAMJARL products. Consumed by <ij-footer> to build cross-links, so a new app is added here once rather than in every site's footer. Categories carry an optional `accent` ({light, dark}); an app may override it with its own. Absent means the mode primary, so nothing renders differently until a family opts in. Order is not significant except for the two always-links, which render in the order listed here. Everything else is selected by category and sorted by id, so the list can be re-sorted without rewriting a single fragment.",
  "meta": {
    "updated": "2026-09-19"
  },
  "categories": {
    "fitness": {
      "label": "Training, movement and health"
    },
    "music": {
      "label": "Audio and music production"
    },
    "web-tools": {
      "label": "Browser and web-page tools"
    },
    "images": {
      "label": "Images and screenshots"
    },
    "play": {
      "label": "Play and art"
    }
  },
  "apps": [
    {
      "id": "its-mono-yo",
      "name": "It's mono, yo!",
      "url": "https://itsmonoyo.iamjarl.com",
      "platform": "Mac",
      "category": "music",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "trimrpix",
      "name": "TrimrPix",
      "url": "https://trimrpix.iamjarl.com",
      "platform": "Mac",
      "category": "images",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "anvil-workout",
      "name": "Anvil Workout",
      "url": "https://anvilworkout.iamjarl.com",
      "platform": "iPhone, iPad, Watch",
      "category": "fitness",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "wodrounds",
      "name": "WODrounds",
      "url": "https://wodrounds.iamjarl.com",
      "platform": "iPhone, iPad, Watch, Mac, TV",
      "category": "fitness",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "wean-nicotine",
      "name": "Wean Nicotine",
      "url": "https://weannicotine.iamjarl.com",
      "platform": "iPhone",
      "category": "fitness",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "its-404-yo",
      "name": "It's 404, yo!",
      "url": "https://its404yo.iamjarl.com",
      "platform": "Mac",
      "category": "music",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "made-by-human",
      "name": "Made by Human",
      "url": "https://madebyhuman.iamjarl.com",
      "platform": "Web",
      "category": null,
      "status": "shipped",
      "listed": true,
      "consumes": false,
      "always": true
    },
    {
      "id": "iamjarl",
      "name": "All projects",
      "url": "https://iamjarl.com",
      "platform": "Web",
      "category": null,
      "status": "shipped",
      "listed": true,
      "consumes": false,
      "always": true
    },
    {
      "id": "echolume",
      "name": "Echolume",
      "url": "https://echolume.iamjarl.com",
      "platform": "Mac",
      "category": "music",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "botlens",
      "name": "BotLens",
      "url": "https://botlens.iamjarl.com",
      "platform": "Chrome",
      "category": "web-tools",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "pagelens",
      "name": "PageLens",
      "url": "https://pagelens.iamjarl.com",
      "platform": "Chrome",
      "category": "web-tools",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "walkful",
      "name": "Walkful",
      "url": "https://walkful.iamjarl.com",
      "platform": "iPhone",
      "category": "fitness",
      "status": "shipped",
      "listed": true,
      "consumes": true
    },
    {
      "id": "trimrpix-ios",
      "name": "TrimrPix for iOS",
      "url": "https://trimrpixforios.iamjarl.com",
      "platform": "iPhone",
      "category": "images",
      "status": "shipped",
      "listed": true,
      "consumes": false
    },
    {
      "id": "tonvault",
      "name": "TonVault",
      "url": "https://tonvault.iamjarl.com",
      "platform": "Mac",
      "category": "music",
      "status": "shipped",
      "listed": true,
      "consumes": true
    },
    {
      "id": "beertuner",
      "name": "BeerTuner",
      "url": "https://beertuner.iamjarl.com",
      "platform": "Web",
      "category": "music",
      "status": "side-project",
      "listed": true,
      "consumes": false
    },
    {
      "id": "emotionwave",
      "name": "EmotionWave",
      "url": "https://emotionwave.iamjarl.com",
      "platform": "Web",
      "category": "music",
      "status": "side-project",
      "listed": true,
      "consumes": false
    },
    {
      "id": "patternaut",
      "name": "Patternaut",
      "url": "https://patternaut.iamjarl.com",
      "platform": "Mac",
      "category": "music",
      "status": "shipped",
      "listed": true,
      "consumes": true
    },
    {
      "id": "get-to-the-movie",
      "name": "Get to the Movie!",
      "url": "https://gettothemovie.iamjarl.com",
      "platform": "Web",
      "category": "web-tools",
      "status": "side-project",
      "listed": true,
      "consumes": false
    },
    {
      "id": "little-rocket",
      "name": "Little Rocket",
      "url": "https://littlerocket.iamjarl.com",
      "platform": "Web",
      "category": "play",
      "status": "side-project",
      "listed": true,
      "consumes": false
    },
    {
      "id": "beef",
      "name": "Beef",
      "url": "https://beef.iamjarl.com",
      "platform": "Web",
      "category": "fitness",
      "status": "side-project",
      "listed": true,
      "consumes": false
    }
  ]
};

// Which cross-links does a given site's footer show?
//
// Pure: no DOM, no fetch, no globals. The custom element is a rendering shell
// over this, so the part with actual decisions in it is testable with the
// repo's plain-assertion harness and no browser.

const DEFAULT_OPTIONS = {
  // Categories with few members would render a near-empty list, so top up from
  // the rest of the registry, least-connected first. See categoryReach below.
  minLinks: 3,
  // Side projects are in the registry so the data is complete, but shipped
  // products are what a footer sells. Flip this to widen the net.
  include: ['shipped'],
};

// How many other apps an app's own category already reaches. An app in a
// two-member category is seen by one footer; one in a four-member category by
// three. Top-up prefers the former, which spreads links towards the apps a
// category cannot reach on its own.
//
// Deliberately computed from the registry and NOT from the result: ranking by
// actual inbound links would make the rule depend on its own output, so two
// runs could disagree and the generated fragments would not be reproducible.
function categoryReach(apps, app) {
  if (!app.category) return Number.MAX_SAFE_INTEGER;
  return apps.filter(a => a.category === app.category && a.id !== app.id).length;
}

function selectLinks(registry, siteId, options = {}) {
  const { minLinks, include } = { ...DEFAULT_OPTIONS, ...options };
  const apps = registry?.apps ?? [];

  const self = apps.find(a => a.id === siteId);
  if (!self) {
    throw new Error(
      `Unknown site "${siteId}". Add it to apps.json, or check the app attribute on <ij-footer>.`
    );
  }

  // Never link to yourself, and never link something marked unlisted.
  const eligible = apps.filter(
    a => a.id !== siteId && a.listed !== false && include.includes(a.status)
  );

  const always = eligible.filter(a => a.always === true);
  const pool = eligible.filter(a => a.always !== true);

  // Sorted by id, not by position in apps.json, so re-sorting the registry
  // cannot rewrite a committed fragment. The always-links are the exception:
  // they are a curated pair and render in the order the registry lists them.
  const byId = (a, b) => (a.id < b.id ? -1 : 1);
  const siblings = self.category
    ? pool.filter(a => a.category === self.category).sort(byId)
    : [];

  const topUp = [];
  if (siblings.length < minLinks) {
    const chosen = new Set(siblings.map(a => a.id));
    const candidates = pool
      .filter(a => !chosen.has(a.id))
      .map(a => ({ app: a, reach: categoryReach(pool, a) }))
      // Least-connected first, then by id. Deliberately NOT by position in
      // apps.json: order would make a cosmetic re-sort of the registry rewrite
      // every committed fragment. Reach already carries the "needs exposure"
      // signal that ordering used to approximate.
      .sort((x, y) => x.reach - y.reach || (x.app.id < y.app.id ? -1 : 1));

    for (const c of candidates) {
      if (siblings.length + topUp.length >= minLinks) break;
      topUp.push(c.app);
    }
  }

  return { self, siblings, topUp, always, links: [...siblings, ...topUp, ...always] };
}

// <ij-footer app="tonvault" tagline="…" layout="stacked|columns">
//
// Renders a site's footer with cross-links to the rest of the portfolio,
// grouped by category so a visitor is offered what they would plausibly want.
//
//   <ij-footer app="tonvault" tagline="An IAMJARL app. Pay once, own it.">
//     <a slot="links" href="/privacy">Privacy</a>
//     <a slot="links" href="/support">Support</a>
//     <p slot="fineprint">© 2026 IAMJARL. Not affiliated with Elektron.</p>
//     <p>© 2026 TonVault</p>   <!-- unslotted: the pre-upgrade fallback -->
//   </ij-footer>
//
// Two slots, because a footer has two kinds of per-site content: the site's own
// links, and the colophon — copyright, legal disclaimers, attribution. Both
// reference footers in the portfolio have that second region, and without a slot
// for it a consuming site would silently lose its legal text on upgrade.
//
// Anything in neither slot is deliberately not rendered. Custom elements show
// their own children until they upgrade, so that content is what a visitor sees
// if this script never loads — a plainer footer rather than none.
//
// layout="stacked" (default) is the WODrounds shape: groups above one another,
// links flowing inline. layout="columns" is the Wean Nicotine shape: a grid of
// groups with links stacked under each heading.


const STYLE = `
:host {
  /* The host page wins if it has tokens; otherwise fall back to the system's
     own values. Never import tokens.shadow.css here — its :host declarations
     would beat the page's and override the site's chosen mode. */
  --_text:    var(--ij-color-text-secondary, rgba(0, 0, 0, 0.70));
  --_heading: var(--ij-color-text-primary,   rgba(0, 0, 0, 1));
  --_link:    var(--ij-color-text-secondary, rgba(0, 0, 0, 0.70));
  --_hover:   var(--ij-color-primary,        #A435D2);
  --_border:  var(--ij-color-border-subtle,  rgba(0, 0, 0, 0.10));
  --_gap:     var(--ij-spacing-sm,   8px);
  --_gap-md:  var(--ij-spacing-lg,  16px);
  --_gap-lg:  var(--ij-spacing-xxl, 24px);
  --_size:    var(--ij-font-size-sm, 14px);
  --_focus:   var(--ij-focus-width,  2px);
  --_offset:  var(--ij-focus-offset, 2px);

  display: block;
  color: var(--_text);
  font-size: var(--_size);
  line-height: var(--ij-line-height-sm, 20px);
}

/* Only for hosts with no token layer at all — a site that defines --ij-*
   already carries its own mode and must not be second-guessed here. */
@media (prefers-color-scheme: dark) {
  :host {
    --_text:    var(--ij-color-text-secondary, rgba(255, 255, 255, 0.75));
    --_heading: var(--ij-color-text-primary,   rgba(255, 255, 255, 1));
    --_link:    var(--ij-color-text-secondary, rgba(255, 255, 255, 0.75));
    --_hover:   var(--ij-color-primary,        #D0FF00);
    --_border:  var(--ij-color-border-subtle,  rgba(255, 255, 255, 0.12));
  }
}

.footer { border-top: 1px solid var(--_border); padding-top: var(--_gap-lg); }
.tagline { color: var(--_heading); margin: 0 0 var(--_gap-lg); }

/* A quiet label, not a shouted one. Both reference footers in the portfolio use
   sentence case at normal weight — no uppercase, no letter-spacing. */
.label {
  color: var(--_heading);
  opacity: var(--ij-opacity-muted, 0.65);
  margin: 0 0 var(--_gap);
}

.groups { display: grid; gap: var(--_gap-lg); margin-bottom: var(--_gap-lg); }
.links { display: flex; flex-wrap: wrap; gap: var(--_gap) var(--_gap-md); }

/* Wean Nicotine's shape: a grid of groups, links stacked under each heading. */
:host([layout="columns"]) .groups {
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--_gap-lg) var(--_gap-lg);
}
:host([layout="columns"]) .links { flex-direction: column; gap: var(--_gap); }

.fineprint { opacity: var(--ij-opacity-muted, 0.65); }
.fineprint ::slotted(*) { margin: 0; }

a, ::slotted(a) {
  color: var(--_link);
  text-decoration: none;
  border-bottom: 1px solid transparent;
}
a:hover, ::slotted(a:hover) { color: var(--_hover); border-bottom-color: currentColor; }
a:focus-visible, ::slotted(a:focus-visible) {
  outline: var(--_focus) solid var(--_hover);
  outline-offset: var(--_offset);
  border-radius: var(--ij-radius-sm, 8px);
}

@media (max-width: 480px) {
  :host([layout="columns"]) .groups { grid-template-columns: 1fr; }
}
`;

const escape = s => String(s).replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// Name only. Neither reference footer annotates links with a platform, and the
// suffix turned a scannable list into noise.
const linkHtml = app => `<a href="${escape(app.url)}">${escape(app.name)}</a>`;

class IjFooter extends HTMLElement {
  static observedAttributes = ['app', 'tagline', 'layout', 'links-label'];

  connectedCallback() {
    this.render();
  }

  attributeChangedCallback() {
    if (this.shadowRoot) this.render();
  }

  render() {
    const app = this.getAttribute('app');
    let selection;
    try {
      selection = selectLinks(REGISTRY, app);
    } catch (err) {
      // A wrong or missing app id must not blank the footer. Attaching a shadow
      // root hides unslotted light DOM, so bail out BEFORE attaching one and the
      // pre-upgrade fallback keeps standing.
      console.error('[ij-footer]', err.message);
      return;
    }

    if (!this.shadowRoot) this.attachShadow({ mode: 'open' });

    const { self, siblings, topUp, always } = selection;
    // One group, not two rows. Made by Human and All projects belong with the
    // apps, the way both reference footers have them.
    const related = [...siblings, ...topUp, ...always];

    // If the page already carries the cross-links, slot them instead of
    // rebuilding. Links generated here exist only after JS runs, and the
    // crawlers that matter most for discovery do not run JS. A site that can
    // inline dist/footers/<app>.html at build time gets the same links in its
    // served HTML; one that cannot keeps generating them here.
    const provided = this.querySelector('[slot="cross-links"]') !== null;
    const tagline = this.getAttribute('tagline');
    const ownLabel = this.getAttribute('links-label') ?? self.name;

    this.shadowRoot.innerHTML = `
      <style>${STYLE}</style>
      <footer class="footer">
        ${tagline ? `<p class="tagline">${escape(tagline)}</p>` : ''}
        <div class="groups">
          <div class="group">
            <p class="label">${escape(ownLabel)}</p>
            <div class="links"><slot name="links"></slot></div>
          </div>
          <nav class="group" aria-labelledby="more">
            <p class="label" id="more">More from IAMJARL</p>
            <div class="links">${provided
              ? '<slot name="cross-links"></slot>'
              : related.map(linkHtml).join('')}</div>
          </nav>
        </div>
        <div class="fineprint"><slot name="fineprint"></slot></div>
      </footer>`;
  }
}

if (!customElements.get('ij-footer')) customElements.define('ij-footer', IjFooter);
