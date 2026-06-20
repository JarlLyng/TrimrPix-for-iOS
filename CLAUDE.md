# CLAUDE.md — TrimrPix for iOS

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## What is TrimrPix?

iOS app that compresses photos from the user's Photos library **in-place** (originals are replaced, no duplicates created). One job: make files smaller. No cloud, no accounts, no internet required.

- **Developer:** Jarl Lyng / [IAMJARL](https://iamjarl.com)
- **Website:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com)
- **License:** [AGPL-3.0](LICENSE) — open source. Source-available; the polished build ships on the App Store. Derivatives must stay AGPL.
- **Price:** $1.99 USD one-time (no in-app purchases, no subscription, no ads)
- **Status:** Launched (App Store app-id 6761081919) — post-launch monitoring (#27)
- **Sister app:** [TrimrPix for macOS](https://trimrpix.iamjarl.com) — separate app with extra features (drag-and-drop, Watch Folder, AVIF/GIF). iOS and macOS have separate websites, support pages, and privacy policies, but link to each other.

## App features (be precise — do not invent features that don't exist)

- **Select & compress** — pick photos via PhotosPicker, choose quality, slide to confirm
- **In-place replacement** — originals are replaced directly in Photos library, no duplicates
- **4 formats supported** — JPEG, PNG, WebP, HEIC. Each photo keeps its **original format** — there is NO user-facing format picker. Format conversion would force every photo through the create-and-delete fallback (Photos rejects in-place format changes, 3302), defeating in-place replacement; it's a macOS-only feature.
- **2 compression modes** — Quality (3 levels) or Target size (per-photo byte budget). NOT a total-batch budget.
- **3 quality levels** — Same (minimal loss), Good (balanced), Smaller (aggressive). NOT "High/Medium/Low"
- **Target-size mode** — pick a per-photo target (500 KB / 1 MB / 2 MB / 5 MB); the service binary-searches lossy quality (JPEG/HEIC/WebP) or palette size (PNG) to fit. Photos already smaller are left unchanged. See `CompressionMode` / `encodeToTarget`.
- **Metadata control** — granular: keep or strip date/time, GPS, camera settings, IPTC, Apple data
- **Savings estimate** — see how much space you'll save before compressing
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

- **iOS 26.2+** (NOT iOS 15, 16, 17, or 18 — specifically 26.2+)
- Runs on **iPhone and iPad** — universal app, content is centered at max 640pt width on wider screens
- Photos library access: full or limited (write access required for in-place replacement)

## Tech stack

- **Swift / iOS 26.2+ / SwiftUI** — UI and app lifecycle
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

### Closed issues (shipped)
- ✅ #1 Dynamic Type support (Larger Text)
- ✅ #2 Reduce Motion support
- ✅ #3 Differentiate without color alone (step indicator)
- ✅ #4 iPad support (640pt max-width centered layout)
- ✅ #15 Competitor analysis (kept in private notes, not in this public repo)
- ✅ #20 App Store screenshots prepared and uploaded
- ✅ #24 Sentry launch diagnostic removed
- ✅ #26 Pristine HEIC replace failure — solved via hybrid in-place + batched copy-delete fallback (commits 7d19e98, 9771388). Zero errors in Sentry over 2 post-fix test runs.

### Photo replacement architecture
In-place replacement via `PHContentEditingOutput` is attempted first. For photos Photos rejects with `PHPhotosErrorInvalidResource` (3302) — typically pristine HEIC with HDR gain map / spatial stereo on iOS 26 — the replacement falls back to creating a new asset from the compressed bytes (preserving creation date, location, and favorite) and deleting the original. All fallback photos within a batch are committed in a single `performChanges` transaction so the user sees exactly one iOS deletion confirmation sheet regardless of how many photos take the fallback path. See `replaceInPhotosLibrary` and `commitPendingFallbacks` in `ImageOptimizationViewModel`.

### Open issues (as of April 2026)

**Testing (manual, needs device):**
- #5 Test all output formats (JPEG, PNG, HEIC, WebP)
- #6 Test large batch compression (10+ photos)
- #7 Verify Dark Mode colors across all screens
- #8 Test iCloud photos compression (download + save back)
- #17 Verify accessibility features on device (VoiceOver, Dynamic Type, Reduce Motion)
- #18 Test iPad layout and functionality

**Testing (automation):**
- #21 Add unit tests for core services

**Bugs / enhancements (not blocking launch):**
- #25 Lazy-load photo data (reduces RAM upfront; current autoreleasepool fix handles typical batches)

**Marketing (launch + post-launch):**
- #9 Record demo video and embed on website
- #10 Activate App Store links and Smart App Banner at launch
- #11 Set up Google Search Console and analytics
- #12 Product Hunt launch
- #13 Community outreach: Reddit, Hacker News, Indie Hackers
- #14 Contact iOS blogs for reviews
- #16 App Store localization (DA, DE, FR, JA)
- #19 Update App Store Connect accessibility declarations at launch

**Future features (v1.1+, surfaced by competitor analysis):**
- ✅ #22 Target-size mode — shipped in 1.1 (`CompressionMode.targetSize`, `encodeToTarget`)
- #23 Share Extension (compress from Photos share sheet)

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
- AEO-optimized FAQ (answers under 60 words, direct answer first)
- Developer personality in copy (E-E-A-T)
- Cross-links to other IAMJARL projects (Made by Human, WODrounds, Wean Nicotine) in all footers
- Apple Smart App Banner prepared as comment (activate with app-id when live)
- Video section prepared as comment (activate with YouTube embed URL)
- All App Store download links are `href="#"` — update with real URL when live

### App Store Connect (prepared)
- **Subtitle:** "Compress Photos In Place" — leads with the in-place differentiator (24 chars, under 30 limit).
- **Keywords:** `in-place photo compressor,no duplicates,compress photos,reduce photo size,target size,free up space,photo compressor no ads,HEIC compress,strip metadata,WebP compressor,replace originals` (note: App Store keywords field is 100 chars — trim to the highest-value subset when entering)
- **Primary Category:** Photo & Video
- **Secondary Category:** Utilities
- **Copyright:** 2026 IAMJARL

## Common tasks

**Add a metadata category**: Add property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress(data:mode:format:)`. `mode` is `.quality` or `.targetSize`. Quality path: `encode()` → `compressWithDestination(lossyQuality:)` (JPEG/WebP/HEIC) or `compressPNG`. Target path: `encodeToTarget` (binary-searches lossy quality, or `compressPNGToTarget` for PNG).

**Add a new step**: Add case to `AppStep`, add view in `ContentView.swift`, update step indicator.

**Change error messages**: Edit `TrimrPixError` — all user-facing error strings are there.
