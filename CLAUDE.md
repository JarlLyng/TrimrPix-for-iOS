# CLAUDE.md — TrimrPix for iOS

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## What is TrimrPix?

iOS app that compresses photos from the user's Photos library **in-place** (originals are replaced, no duplicates created). One job: make files smaller. No cloud, no accounts, no internet required.

- **Developer:** Jarl Lyng / [IAMJARL](https://iamjarl.com)
- **Website:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com)
- **License:** Private — all rights reserved (NOT open source)
- **Price:** Free (no in-app purchases)
- **Status:** Pre-launch (Q2 2026)
- **Sister app:** [TrimrPix for macOS](https://trimrpix.iamjarl.com) — separate app with extra features (drag-and-drop, Watch Folder, AVIF/GIF). iOS and macOS have separate websites, support pages, and privacy policies, but link to each other.

## App features (be precise — do not invent features that don't exist)

- **Select & compress** — pick photos via PhotosPicker, choose quality and format, slide to confirm
- **In-place replacement** — originals are replaced directly in Photos library, no duplicates
- **4 output formats** — JPEG, PNG, WebP, HEIC
- **3 quality levels** — Same (minimal loss), Good (balanced), Smaller (aggressive). NOT "High/Medium/Low"
- **Metadata control** — granular: keep or strip date/time, GPS, camera settings, IPTC, Apple data
- **Savings estimate** — see how much space you'll save before compressing
- **iCloud support** — downloads iCloud photos, compresses, saves back
- **Fully offline** — no cloud, no accounts, no internet required
- **Privacy-first** — only data collection is anonymous Sentry crash reports (stack traces, device type, iOS version, app version — no personal data)

### Features that do NOT exist (common hallucination targets)
- No batch "entire library" mode — user selects specific photos
- No import/export of compression presets
- No background processing while app is closed
- No before/after preview comparison
- No Apple Watch support
- Not open source — repo is private

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

### 🚨 Current launch blocker
**#26** — pristine HEIC photos from iPhone 16 Pro Max / iOS 26 fail in-place replace with `PHPhotosErrorInvalidResource` (3302). Verified NOT a format/encoding bug via passthrough diagnostic. Hypothesis: `PhotosPickerItem.loadTransferable` drops auxiliary image data (HDR gain map, spatial stereo) required for commit validation. Three options documented in the issue; **Option A (PHAssetResourceManager for raw bytes) is recommended** and solves #25 for free. **Start here next session.**

### Closed issues (shipped)
- ✅ #1 Dynamic Type support (Larger Text)
- ✅ #2 Reduce Motion support
- ✅ #3 Differentiate without color alone (step indicator)
- ✅ #4 iPad support (640pt max-width centered layout)
- ✅ #15 Competitor analysis → `docs/COMPETITOR_ANALYSIS.md`

### Previously resolved (same session as #26 work)
- Watchdog-termination crash on batch compress — fixed via autoreleasepool + early releaseData() (commit b46eb1a)
- Full Sentry observability for photo-replace flow — capture NSError userInfo, breadcrumbs at every step, primaryResourceUTI, adjustmentFormat (commits d5ba10a, 2588035)

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

**Bugs / must-fix before launch:**
- 🚨 **#26 Pristine HEIC photos fail in-place replace (3302)** — launch blocker, see top of section
- #24 Remove Sentry launch diagnostic before App Store submission
- #25 Lazy-load photo data (reduces RAM; subsumed by #26's recommended fix)

**Marketing (launch + post-launch):**
- #9 Record demo video and embed on website
- #10 Activate App Store links and Smart App Banner at launch
- #11 Set up Google Search Console and analytics
- #12 Product Hunt launch
- #13 Community outreach: Reddit, Hacker News, Indie Hackers
- #14 Contact iOS blogs for reviews
- #16 App Store localization (DA, DE, FR, JA)
- #19 Update App Store Connect accessibility declarations at launch
- #20 Prepare App Store screenshots (iPhone + iPad)

**Future features (v1.1+, surfaced by competitor analysis):**
- #22 Target-size mode (compress to fit a specific file size)
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
| `docs/SEO_STRATEGY.md` | SEO & GEO strategy with current implementation status and action plan |
| `docs/COMPETITOR_ANALYSIS.md` | Top 5 competitor breakdown, differentiators, positioning recommendations |
| `docs/screenshot-{1-4}-*.png` | 4 app screenshots used on website |

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
- **Subtitle:** "Compress Photos In Place" — leads with differentiator (24 chars, under 30 limit). See `docs/COMPETITOR_ANALYSIS.md` for rationale.
- **Keywords:** `in-place photo compressor,no duplicates,compress photos,reduce photo size,free up space,photo compressor no ads,HEIC compress,strip metadata,WebP compressor,replace originals`
- **Primary Category:** Photo & Video
- **Secondary Category:** Utilities
- **Copyright:** 2026 IAMJARL

## Common tasks

**Add a metadata category**: Add property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress()`. Format-specific logic in `compressWithDestination` (JPEG/WebP/HEIC) and `compressPNG`.

**Add a new step**: Add case to `AppStep`, add view in `ContentView.swift`, update step indicator.

**Change error messages**: Edit `TrimrPixError` — all user-facing error strings are there.
