# AGENTS.md — TrimrPix for iOS

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## Boundaries: work only in this repo

- Commit, push and open pull requests **only in this repo**. Never edit, commit to, push to or
  open a pull request in another IAMJARL repo, and that includes `iamjarl-design`.
- To ask another repo for something, **open an issue there**. Public repos get findings, never
  measured numbers. If it is strategic, or not safe in public, it goes to the private hub instead.
- The one place outside this repo you write is this app's own folder in the private hub
  (`TrimrPix-iOS/`). Shared hub files (`PORTFOLIO.md`, the standards, `tools/`) are changed from
  inside the hub; if one needs changing, open an issue there.
- If a task seems to need a change in another repo, stop, open the issue, and carry on with what
  this repo can do.

## What is TrimrPix?

iOS app that compresses photos from the user's Photos library **in-place** (originals are replaced, no duplicates created). One job: make files smaller. No cloud, no accounts, no internet required.

- **Developer:** Jarl Lyng / [IAMJARL](https://iamjarl.com)
- **Website:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com)
- **License:** [AGPL-3.0](LICENSE) — open source. Source-available; the polished build ships on the App Store. Derivatives must stay AGPL.
- **Price:** $1.99 USD one-time (no in-app purchases, no subscription, no ads)
- **Status:** Live on the App Store (app-id 6761081919). Current version **1.3** (released 2026-09)
- **Sister app:** [TrimrPix for macOS](https://trimrpix.iamjarl.com) — separate app with extra features (drag-and-drop, Watch Folder, AVIF/GIF). iOS and macOS have separate websites, support pages, and privacy policies, but link to each other.

## App features (be precise — do not invent features that don't exist)

- **Select & compress** — pick photos via PhotosPicker, choose quality, slide to confirm
- **In-place replacement** — originals are replaced directly in Photos library, no duplicates
- **4 formats supported** — JPEG, PNG, WebP, HEIC. Each photo keeps its **original format** — there is NO user-facing format picker. Format conversion would force every photo through the create-and-delete fallback (Photos rejects in-place format changes, 3302), defeating in-place replacement; it's a macOS-only feature.
- **2 compression modes** — Quality (3 levels) or Target size (per-photo byte budget). NOT a total-batch budget.
- **3 quality levels** — Same (minimal loss), Good (balanced), Smaller (aggressive). NOT "High/Medium/Low"
- **Target-size mode** — pick a per-photo target (500 KB / 1 MB / 2 MB / 5 MB, or a **custom** value the user types in MB); the service binary-searches lossy quality (JPEG/HEIC/WebP) or palette size (PNG) to fit. Photos already smaller are left unchanged. See `CompressionMode` / `TargetSizeOption` / `encodeToTarget`. Custom bytes are clamped 50 KB–50 MB (`customTargetBytes`).
- **Metadata control** — granular: keep or strip date/time, GPS, camera settings, IPTC, Apple data
- **Savings estimate** — see how much space you'll save before compressing (percentage + absolute size)
- **Lifetime savings counter** — total bytes saved across all runs, shown on the result screen. Stored locally in UserDefaults, never transmitted (disclosed in privacy policy)
- **iCloud support** — downloads iCloud photos, compresses, saves back
- **Fully offline** — no cloud, no accounts, no internet required
- **Privacy-first** — only data collection is anonymous Sentry crash reports (stack traces, device type, iOS version, app version — no personal data)
- **Localized** — EN (base) + DA, DE, FR, JA, in-app via `TrimrPix for iOS/Localizable.xcstrings` (String Catalog). DA is native-quality; DE/FR/JA are first-pass and should get a native review. Add UI strings as `Text("literal")` or `String(localized:)`; model/error display strings localize at their source (e.g. `CompressionQuality.displayName`, `TrimrPixError`). App Store *metadata* localization (DA/DE/FR/JA listings) is separate — done in App Store Connect at release.

### Features that do NOT exist (common hallucination targets)
- No batch "entire library" mode — user selects specific photos
- No import/export of compression presets
- No background processing while app is closed
- No before/after preview comparison
- No Apple Watch support

## Requirements

- **iOS 17.0+** — lowered from 26.2 in #53, which was an unexamined Xcode default rather than a
  decision. `@Observable` is what sets the floor at 17; there are no `@available` guards and no
  iOS 26-era APIs in the sources. Verified end-to-end on an iOS 18.2 simulator (picker, estimate,
  target-size and custom-size paths all work). **Still unverified below 18.2** — no iOS 17 runtime
  was installed to test against, and in-place replacement plus the HEIC 3302 fallback were
  originally developed against iOS 26 behavior.
- Runs on **iPhone and iPad** — universal app, content is centered at max 640pt width on wider screens
- Photos library access: full or limited (write access required for in-place replacement)

## Tech stack

- **Swift / SwiftUI** — UI and app lifecycle (deployment target iOS 17.0)
- **PhotosUI** — `PhotosPicker` for image selection (works without permission)
- **Photos** — `PHContentEditingOutput` for in-place replacement (requires `.authorized` or `.limited`)
- **ImageIO / Core Graphics** — compression, metadata processing
- **StoreKit** — `requestReview()` after successful compression
- **Sentry** — crash/performance monitoring (SPM, static framework)
- **IAMJARLDesignTokens** — design tokens (SPM, github.com/JarlLyng/iamjarl-design)

## Architecture at a glance

MVVM, single ViewModel, step-based navigation. Details: [docs/architecture.md](docs/architecture.md).

```
Views (SwiftUI)  →  ImageOptimizationViewModel (@Observable, @MainActor)  →  CompressionService (nonisolated, Sendable)
```

**App flow**: `selectPhotos` → `configure` → `confirm` → `compressing` → `result`

## Key files

| File | Purpose |
|------|---------|
| `TrimrPix_for_iOSApp.swift` | Entry point, Sentry init |
| `ContentView.swift` | All 5 step views + Photos access alert |
| `ViewModels/ImageOptimizationViewModel.swift` | All state, compression orchestration, Photos library replacement |
| `Services/CompressionService.swift` | JPEG/PNG/WebP/HEIC compression via ImageIO |
| `Services/ColorQuantizer.swift` | Median-cut color quantization for lossy PNG |
| `Models/MetadataStrippingOptions.swift` | Granular metadata control (keep/strip per category) |
| `Models/ImageItem.swift` | Per-image state |
| `Views/SlideToConfirmView.swift` | Drag gesture confirmation (85% threshold) |

## Photos permission model

`PhotosPicker` works **without** any permission — Apple handles it out-of-process. But **writing** back to the library requires `.readWrite` authorization (`.authorized` or `.limited` both work). If denied, the app shows an alert with an "Open Settings" button. See `ensurePhotosWriteAccess()` in the ViewModel.

## Concurrency model

- Project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `CompressionService` is `nonisolated` + `Sendable`
- Heavy compression runs in `Task.detached(priority: .userInitiated)`
- `compress()` spawns a fire-and-forget `Task` (supports cancellation)
- `PHAsset.fetchAssets` runs in a detached task to avoid blocking UI
- `requestContentEditingInput` is bridged via `withCheckedThrowingContinuation`

## Setup

1. Copy `Secrets.swift.template` → `Secrets.swift`, fill in Sentry values
2. Create `Sentry.xcconfig` with `SENTRY_AUTH_TOKEN = <token>` (for dSYM upload build phase)
3. File → Packages → Resolve Package Versions in Xcode

## Build notes

- **"Upload Symbols Failed"** warning in Xcode is expected and harmless (Sentry static framework via SPM)
- **Sandbox disabled on Release** for sentry-cli network access
- **sentry-cli** must be installed (`brew install getsentry/tools/sentry-cli`)

## Roadmap & issues

Feature requests, bugs, and future work are tracked as **GitHub Issues** on the repo — not in markdown files. Always create an issue for planned work so it's visible in the roadmap.

**Labels:** `enhancement`, `accessibility`, `testing`, `bug`, `marketing`

Before starting new work, check open issues: `gh issue list`

### Shipped — notable decisions worth knowing
Full list: `gh issue list --state closed`. These are the ones that shaped the code:

- ✅ **#26** Pristine HEIC replace failure — hybrid in-place + batched copy-delete fallback (commits 7d19e98, 9771388). See *Photo replacement architecture* below.
- ✅ **#30** Format picker removed — it had no effect on output, since in-place replace always keeps the original format.
- ✅ **#22** Target-size mode (1.1) · **#16** Localization (1.2) · **#21** Unit tests (1.2)
- ✅ **#23** Share Extension — closed as **won't do**: a share extension cannot do in-place replacement, which is the whole point of the app.
- ✅ **#28/#29** Sentry hardening — crash screenshots and view hierarchy disabled; auth token kept out of the binary.
- ✅ **#1–#4** Accessibility (Dynamic Type, Reduce Motion, non-color differentiation) and iPad support.

### Photo replacement architecture
In-place replacement via `PHContentEditingOutput` is attempted first. For photos Photos rejects with `PHPhotosErrorInvalidResource` (3302) — typically pristine HEIC with HDR gain map / spatial stereo on iOS 26 — the replacement falls back to creating a new asset from the compressed bytes (preserving creation date, location, and favorite) and deleting the original. All fallback photos within a batch are committed in a single `performChanges` transaction so the user sees exactly one iOS deletion confirmation sheet regardless of how many photos take the fallback path. See `replaceInPhotosLibrary` and `commitPendingFallbacks` in `ImageOptimizationViewModel`.

### Open issues — **always verify with `gh issue list`**
This list drifts. Snapshot as of **2026-09** (11 open):

**Highest impact:**
- ~~#53 Deployment target~~ **lowered to iOS 17.0** (unreleased; ships in the next version). At release, update the marketing site — `docs/index.html` (hero line + `operatingSystem` in the JSON-LD) and `docs/llms.txt` still say "iOS 26.2 or later", which stays true until the new build is live.

**Version-locked App Store metadata — these can only change with a version submission, so batch them into one release:**
- #51 Subtitles untranslated in da/de/fr (keywords *are* translated; subtitle is one of only three indexed fields)
- #52 App name uses 8 of 30 chars in every locale
- Not yet an issue, recorded in the strategy hub's `app-store-copy.md`: the live description still describes Target size as presets-only (1.3 added custom), and the screenshots still show the format picker removed in 1.1.

**Technical debt:**
- #50 Design system pinned to v0.1.4; current is v1.2.1 (check `MIGRATION.md` — the `lineHeights` rename is breaking)
- #17 Verify accessibility on device (VoiceOver, Dynamic Type, Reduce Motion)

**Marketing:** #9 demo video · #13 Reddit/HN/Indie Hackers · #14 iOS blog pitches · #44 Indie Hackers updates · #48 llms.txt developer story · #49 localized site (low priority)

## Marketing site

Hosted via GitHub Pages from `docs/` on `main` branch at [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com). Sister app: [trimrpix.iamjarl.com](https://trimrpix.iamjarl.com) (macOS).

### Site structure
| File | Purpose |
|------|---------|
| `docs/index.html` | Landing page — hero, highlights, screenshots, features, how-it-works, CTA, FAQ, privacy, footer |
| `docs/support.html` | Dedicated support page — troubleshooting, FAQ link, contact, macOS cross-link |
| `docs/privacy.html` | Dedicated privacy policy — data collection (Sentry only), on-device processing, children's privacy |
| `docs/CNAME` | Custom domain: `trimrpixforios.iamjarl.com` |
| `docs/screenshot-{1-4}-*.png` | 4 app screenshots used on website |

> SEO and competitor-analysis notes are kept in private notes outside this public repo.

### SEO already implemented
- Canonical URLs, Open Graph, Twitter Cards on all pages
- Schema.org `SoftwareApplication` + `FAQPage` structured data (JSON-LD)
- BreadcrumbList JSON-LD on support.html and privacy.html
- `sitemap.xml` and `robots.txt` in `docs/`
- Favicon set (`favicon-16/32.png`, `apple-touch-icon.png`), `site.webmanifest`, `theme-color` — generated from the app icon
- `llms.txt` (GEO — structured app facts for AI answer engines)
- AEO-optimized FAQ (answers under 60 words, direct answer first)
- Developer personality in copy (E-E-A-T)
- Cross-links to other IAMJARL projects (Made by Human, WODrounds, Wean Nicotine) in all footers
- Apple Smart App Banner prepared as comment (activate with app-id when live)
- Video section prepared as comment (activate with YouTube embed URL)
- All App Store download links are `href="#"` — update with real URL when live

### App Store Connect
- **Primary Category:** Photo & Video · **Secondary:** Utilities · **Copyright:** 2026 IAMJARL
- **Listing copy (name, subtitle, keywords, description, promo, What's New) lives in the private
  strategy hub**, not here: `iamjarl-strategy/TrimrPix-iOS/app-store-copy.md`. That file mirrors
  what is actually live and is the only place to trust for current values.
- ⚠️ **Do not reuse the old "prepared" copy that used to sit here.** It listed the subtitle as
  "Compress Photos In Place", which was a pre-launch draft that never shipped — the live subtitle
  read from ASC is "Shrink photos, keep quality" (see #51). Pre-launch drafts and live values had
  drifted apart unnoticed, which is exactly why the listing copy now has one owner.

## Common tasks

**Add a metadata category**: Add property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress(data:mode:format:)`. `mode` is `.quality` or `.targetSize`. Quality path: `encode()` → `compressWithDestination(lossyQuality:)` (JPEG/WebP/HEIC) or `compressPNG`. Target path: `encodeToTarget` (binary-searches lossy quality, or `compressPNGToTarget` for PNG).

**Add a new step**: Add case to `AppStep`, add view in `ContentView.swift`, update step indicator.

**Change error messages**: Edit `TrimrPixError` — all user-facing error strings are there.
