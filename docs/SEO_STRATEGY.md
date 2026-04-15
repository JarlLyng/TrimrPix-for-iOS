# SEO & GEO Strategi for TrimrPix for iOS

Sidst opdateret: 15. april 2026

---

## Om projektet

**TrimrPix for iOS** er en iPhone-app der komprimerer fotos in-place i brugerens Photos-bibliotek. Appen er 100% offline, kræver ingen konti, og sender aldrig fotos til en server. Den eneste dataindsamling er anonyme crash-rapporter via Sentry (stack traces, device type, iOS-version, app-version — ingen persondata).

**Udvikler:** Jarl Lyng / [IAMJARL](https://iamjarl.com)

### Kernefeatures
- Vælg fotos fra Photos-biblioteket, komprimer, og erstat originalerne in-place (ingen duplikater)
- 4 formater: JPEG, PNG, WebP, HEIC
- 3 kvalitetsniveauer: Same (minimal loss), Good (balanceret), Smaller (aggressiv)
- Granulær metadata-kontrol: behold/fjern dato, GPS, kameraindstillinger, copyright, Apple-data
- Savings estimate før komprimering
- iCloud-kompatibel (downloader, komprimerer, gemmer tilbage)
- Kræver iOS 26.2+

### Prismodel
Gratis (ingen in-app purchases pt.)

### Søsterapp
**TrimrPix for macOS** — separat app med ekstra features (drag-and-drop, Watch Folder, AVIF/GIF). Eget website: [trimrpix.iamjarl.com](https://trimrpix.iamjarl.com). De to apps har separate marketing-sider, support-sider og privacy policies, men linker til hinanden.

---

## Nuværende status (pr. 15. april 2026)

### Marketing-website
- **URL:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com)
- **Hosting:** GitHub Pages fra `docs/`-mappen på `main`-branch med CNAME
- **Sider:**
  - `index.html` — landingsside (hero, highlights, screenshots, features, how-it-works, CTA, FAQ, privacy-kort, footer)
  - `support.html` — dedikeret support-side (FAQ-link, troubleshooting, kontakt, macOS-krydslink)
  - `privacy.html` — dedikeret privacy policy (data collection, Sentry, on-device processing, børn)

### Allerede implementeret SEO
- Canonical URL på alle 3 sider
- Open Graph tags (title, description, type, url, image)
- Twitter Card tags (summary_large_image)
- `meta name="keywords"` med primære søgeord
- Schema.org `SoftwareApplication` structured data (JSON-LD)
- Schema.org `FAQPage` structured data med 6 spørgsmål (JSON-LD)
- Semantisk HTML (sections, headings, nav, footer)
- `loading="lazy"` på screenshots
- 4 app-screenshots i `docs/` (select, configure, confirm, result)
- AEO-optimerede FAQ-svar (alle under 60 ord, direkte svar først)
- Developer personality i copy ("I built TrimrPix to do one thing well")
- Intern linkstruktur mellem alle 3 sider + krydslinks til macOS-version
- Mobile responsive design
- Sticky nav med backdrop blur

### Forberedt men ikke aktiveret
- **Apple Smart App Banner:** `<meta name="apple-itunes-app">` ligger som HTML-kommentar — aktiver med rigtig app-id når appen er live
- **Video-sektion:** HTML/CSS er klar i index.html som kommentar — aktiver med YouTube embed-URL når demo-video er optaget
- **App Store links:** Alle "Download on the App Store"-knapper og footer-link peger på `href="#"` — opdater med rigtig App Store URL

### App Store Connect (forberedt)
- **Subtitle:** "Compress Photos on iPhone"
- **Keywords:** `compress photos,reduce photo size,free up space,photo compressor,shrink photos,strip metadata,HEIC compress,photo optimizer,save storage,offline photos`
- **Primary Category:** Photo & Video
- **Secondary Category:** Utilities
- **Privacy:** Crash Data (Sentry) — Not Linked to Identity, Not Used for Tracking, App Functionality
- **Privacy Policy URL:** `https://trimrpixforios.iamjarl.com/privacy.html`
- **Support URL:** `https://trimrpixforios.iamjarl.com/support.html`
- **Copyright:** `2026 IAMJARL`

---

## SEO Strategi

### 1. Målgruppe og søgeintention

**Primær målgruppe:** iOS-brugere der mangler lagerplads på deres iPhone og ønsker en sikker måde at komprimere fotos in-place uden cloud-uploads.

**Søgeintentioner:**
- Informational: "hvordan frigør jeg plads på iPhone", "hvad er HEIC format"
- Transactional: "compress photos app iPhone", "reduce photo size iOS app"
- Navigational: "TrimrPix app", "TrimrPix iOS download"

### 2. Nøgleord (Keywords) & Branded Search

#### Primære søgeord (High Intent)
- "compress photos iOS"
- "reduce photo size iPhone"
- "in-place photo compressor iOS"
- "free up space iPhone photos"
- "shrink photos iPhone app"
- "strip EXIF data iOS"
- "HEIC compressor iPhone"
- "offline photo compressor iOS"

#### Long-tail søgeord
- "how to compress photos on iPhone without losing quality"
- "reduce iPhone photo file size without cloud"
- "remove GPS location from photos iPhone"
- "convert HEIC to JPEG iPhone"
- "best photo compressor app for iPhone 2026"

#### Branded Search Taktik
Forsøg at få brugere (via SoMe, PR, YouTube, communities) til at søge på kombinationer som `"TrimrPix compress photos"` eller `"TrimrPix iPhone"`. Når brugere søger efter dit brand + søgeord, overbeviser det hurtigt Google om, at du "ejer" emnet.

Konkrete taktikker:
- Brug altid "TrimrPix" i video-titler og social media posts
- Opfordr anmeldere til at nævne "TrimrPix" med navn
- Skriv artikler/blog posts med "TrimrPix" i titlen

### 3. Teknisk SEO

#### Allerede på plads
- Core Web Vitals: Sitet er statisk HTML, loader lynhurtigt, ingen JavaScript-frameworks
- Schema.org structured data (SoftwareApplication + FAQPage)
- Canonical URLs, Open Graph, Twitter Cards
- Semantisk HTML-struktur
- Mobile responsive

#### Mangler / næste skridt
- **Apple Smart App Banner:** Aktiver `<meta name="apple-itunes-app" content="app-id=XXXXXXX">` så snart appen er live i App Store
- **Sitemap:** Overvej `sitemap.xml` i `docs/` (3 sider er småt, men det skader ikke)
- **robots.txt:** Ikke strengt nødvendigt for GitHub Pages, men kan tilføjes for klarhed
- **Image optimization:** Screenshots er PNG — overvej WebP-versioner med `<picture>`-tag for hurtigere load
- **Alt-tekster:** Allerede implementeret på screenshots ("TrimrPix select photos screen" osv.)

### 4. AI Search Optimering (AEO)

For at blive vist i **Google AI Overviews**, **ChatGPT**, **Perplexity** og lignende AI-søgeværktøjer:

#### Allerede implementeret
- FAQ'er med specifikke H3-overskrifter formuleret som spørgsmål
- Korte, direkte svar (under 60 ord) som første sætning under hver overskrift
- FAQPage structured data der matcher HTML-indholdet
- Klart defineret "hvad er dette produkt" i Schema.org

#### Principper at følge
- Formuler overskrifter som reelle spørgsmål brugere stiller ("How much space can I save?")
- Giv et kort, definitivt svar i første 1-2 sætninger, uddyb derefter
- Undgå vage svar — specifikke tal og fakta ("30-80% reduction") vinder i AI-citater
- Hold FAQ-svar opdateret med aktuelle features

### 5. Indholdsstrategi & E-E-A-T

I 2026 er tillid det absolut største ranking-parameter, fordi internettet flyder over med AI-genereret "slop":

#### Ægte menneskeligt indhold
Skriv som en ægte udvikler der løser et reelt problem. Fortæl historien om *hvorfor* du byggede en 100% offline app. "Lived experience" vinder over generisk marketing-copy.

**Nuværende tone på sitet (bevar denne):**
- "I built TrimrPix to do one thing well: make your photo files smaller."
- "Your iPhone is full, but your photos matter."
- "Stop deleting memories to free up space."
- "That's the whole point — I built it this way because your photos are nobody else's business."

#### Video (YouTube-effekten)
Video skaber massiv tillid. Lav små demonstrationer og læg dem på YouTube. Embed derefter videoerne direkte på sitet. Det øger konverteringen og dwell time.

**Video-plan:**
1. Optag en 60-90 sekunders "Sådan virker det" demo med din stemme
2. Upload til YouTube med titel der indeholder "TrimrPix"
3. Aktiver video-sektionen i `index.html` (HTML/CSS er klar, ligger som kommentar)
4. Tilføj VideoObject structured data til JSON-LD

#### Brand Mentions & Unlinked Mentions
Få andre til at omtale TrimrPix, også selvom de ikke direkte linker til dig. AI-søgemaskiner bruger "unlinked mentions" til at skabe autoritet.

### 6. App Store Optimization (ASO)

ASO er tæt forbundet med web-SEO — App Store-placeringer påvirker branded search, og branded search påvirker App Store-placeringer.

#### Nuværende ASO-setup
- **App Name:** TrimrPix
- **Subtitle:** "Compress Photos on iPhone" (30 tegn, keyword-rig)
- **Keywords:** `compress photos,reduce photo size,free up space,photo compressor,shrink photos,strip metadata,HEIC compress,photo optimizer,save storage,offline photos` (100 tegn)
- **Primary Category:** Photo & Video
- **Secondary Category:** Utilities

#### ASO-principper
- **Subtitle** er det vigtigste keyword-felt efter app-navnet — brug det til high-intent søgeord
- **Keywords-feltet** er usynligt for brugere, brug det til synonymer og variationer der ikke passer i titlen
- **Undgå duplikering:** Ord fra app-navnet og subtitlen er allerede indexeret — gentag dem ikke i keyword-feltet
- **Ratings & reviews:** Brug `requestReview()` (allerede implementeret) efter succesfuld komprimering for at opbygge ratings
- **Screenshots i App Store:** Brug de 4 screenshots vi allerede har (select, configure, confirm, result) — overvej at tilføje tekst-overlays
- **Beskrivelse:** Skriv med developer personality, gentag primære søgeord naturligt, fremhæv "offline" og "privacy" da det differentierer fra konkurrenter

#### Keyword-iteration
Brug App Store Connect Analytics til at måle impressions og conversion rate per søgeord. Udskift underperformende keywords hver 4-6 uger. Fokuser på søgeord med høj conversion rate fremfor høj volumen.

### 7. Backlink-strategi

#### Tier 1: Indie dev communities (højeste ROI)
- **Reddit:** r/iOSProgramming, r/SwiftUI, r/apple, r/iphone — del udviklerhistorien, ikke bare appen
- **Hacker News:** "Show HN: I built an offline photo compressor for iPhone" — HN elsker privacy-fokuserede, single-purpose tools
- **Indie Hackers:** Perfekt platform for at dele "built in public"-historien
- **Twitter/X:** iOS dev-community, #buildinpublic, #indiedev

#### Tier 2: Produkt-sites
- **Product Hunt:** Launch med en god tagline ("Your photos are nobody else's business")
- **AlternativeTo:** List TrimrPix som alternativ til cloud-baserede compression-services
- **Setapp / AppSumo:** Overvej distributionspartnerskaber

#### Tier 3: Presse & blogs
- **iOS-blogs:** 9to5Mac, MacStories, iMore — pitch privacy-angle og "no-cloud" differentiering
- **Utility app roundups:** "Best iPhone storage apps 2026" — kontakt forfattere direkte

#### Principper
- Prioriter relevans over volumen — én backlink fra 9to5Mac er mere værd end 50 fra tilfældige directories
- Del en ægte historie, ikke en pressemeddelelse
- Link altid til `trimrpixforios.iamjarl.com` (ikke App Store URL) for at opbygge domæne-autoritet

### 8. Konkurrentanalyse

#### Hvem rangerer på vores søgeord?

Udfør en konkurrentanalyse for disse søgninger:
- "compress photos iPhone" — hvem er top 5 i Google og App Store?
- "reduce photo size iPhone app" — hvilke apps og websites dominerer?
- "free up space iPhone photos" — er det Apple-support, blogs, eller apps?

#### Hvad skal vi analysere per konkurrent?
- Deres landing page: SEO-setup, features-kommunikation, copy-tone
- App Store listing: titel, subtitle, keywords, screenshots, ratings
- Backlink-profil (brug Ahrefs/Semrush free tier)
- Social media-tilstedeværelse
- Pris vs. features

#### Differentieringspunkter for TrimrPix
- **100% offline** — de fleste konkurrenter uploader til cloud
- **In-place replacement** — ingen duplikater, ægte pladsbesparelse
- **Metadata-kontrol** — granulær kontrol er sjælden i denne kategori
- **Privacy-first** — ingen data collection ud over anonyme crash reports
- **Developer personality** — indie dev vs. korporat app

### 9. Målepunkter & KPI'er

#### Web (Google Search Console + Analytics)
| KPI | Mål (3 mdr.) | Mål (6 mdr.) |
|-----|---------------|---------------|
| Organic impressions | 5.000/mdr. | 20.000/mdr. |
| Organic clicks | 500/mdr. | 2.000/mdr. |
| CTR fra søgeresultater | > 5% | > 8% |
| Branded search volume | Baseline → 2x | Baseline → 5x |
| Backlinks (referring domains) | 10 | 30 |
| Core Web Vitals | Alle "Good" | Alle "Good" |

#### App Store (App Store Connect Analytics)
| KPI | Mål (3 mdr.) | Mål (6 mdr.) |
|-----|---------------|---------------|
| App Store impressions | 10.000/mdr. | 50.000/mdr. |
| Product page views | 2.000/mdr. | 10.000/mdr. |
| Conversion rate | > 30% | > 35% |
| Average rating | > 4.5 | > 4.7 |
| Downloads | 500/mdr. | 2.000/mdr. |

#### AI Search
| KPI | Mål |
|-----|-----|
| Google AI Overview appearances | Tracker manuelt — søg primære queries ugentligt |
| Perplexity mentions | Søg "TrimrPix" + primære queries månedligt |
| ChatGPT mentions | Test med "best offline photo compressor iPhone" månedligt |

#### Målefrekvens
- **Ugentligt:** Google Search Console (impressions, clicks, CTR, position)
- **Månedligt:** App Store Analytics, backlink audit, AI search check, keyword ranking
- **Kvartalsvist:** Konkurrentanalyse, keyword-iteration, strategijustering

---

## GEO (Lokaliserings) Strategi

### 1. Prioriterede markeder (Tier 1)
- **USA / UK / Canada (EN):** Det primære marked. Højeste købekraft og iOS-markedsandel. Alt indhold og ASO er på engelsk.
- **Danmark / Norden (DA, SV, NO):** Sandkassemiljø til at teste og perfektere konverteringer. Udviklerens hjemmemarked giver autentisk E-E-A-T.

### 2. Tier 2 markeder
- **Tyskland, Frankrig, Japan:** Store iOS-markeder med stærk købekraft, hvor app-oversættelse har en enorm konverteringseffekt. Engelsk virker markant dårligere her.

### 3. Lokaliseringsstrategi

#### App Store lokalisering (lavthængende frugt)
- Oversæt App Store metadata (titel, subtitle, description, keywords) til DA, DE, FR, JA
- Kræver ingen kodeændringer — gøres direkte i App Store Connect
- **Trigger:** Implementer når appen har > 500 downloads/måned på engelsk

#### Website lokalisering (fase 2)
- Opret sprogversioner under `/da/`, `/de/`, osv.
- Implementer `<link rel="alternate" hreflang="x">` tags for at undgå duplicate content
- **Trigger:** Implementer når App Store lokalisering viser positiv effekt
- Bevar developer personality i oversættelser — brug ikke maskinoversættelse direkte

### 4. Kulturel tilpasning
- **Norden:** Privacy-argumentet resonerer ekstra stærkt (GDPR-bevidsthed)
- **Tyskland:** "Made by indie developer" + dataminimering er stærke salgspunkter
- **Japan:** Fokuser på kvalitet, brugeroplevelse og "ingen reklamer"

---

## Handlingsplan

Alle konkrete opgaver er tracket som **GitHub Issues** med label `marketing`. Se `gh issue list --label marketing` for aktuel status.

### Faser (rækkefølge)
1. **Launch** — demo-video, App Store links, Search Console, analytics (#9, #10, #11)
2. **Post-launch** — Product Hunt, community outreach, blog reviews, konkurrentanalyse (#12, #13, #14, #15)
3. **Optimering** — keyword-iteration, A/B test screenshots, blog content, backlinks
4. **Skalering** — App Store lokalisering, website lokalisering, paid acquisition (#16)

---

## Filreferencer

| Fil | Indhold |
|-----|---------|
| `docs/index.html` | Marketing-landingsside med al SEO markup |
| `docs/support.html` | Dedikeret support-side for iOS-appen |
| `docs/privacy.html` | Dedikeret privacy policy for iOS-appen |
| `docs/CNAME` | Custom domain: `trimrpixforios.iamjarl.com` |
| `docs/screenshot-{1-4}-*.png` | 4 app-screenshots brugt på website |
| `CLAUDE.md` | Teknisk projektdokumentation |
| `README.md` | Repo-oversigt med links |
