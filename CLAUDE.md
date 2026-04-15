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
- No iPad-optimized layout (yet — see GitHub Issues)
- Not open source — repo is private

## Requirements

- **iOS 26.2+** (NOT iOS 15, 16, 17, or 18 — specifically 26.2+)
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

### Current open issues (as of April 2026)
1. Add Dynamic Type support (Larger Text) — `enhancement`, `accessibility`
2. Respect Reduced Motion accessibility setting — `enhancement`, `accessibility`
3. Differentiate without color alone — `enhancement`, `accessibility`
4. iPad support — `enhancement`
5. Test all output formats (JPEG, PNG, HEIC, WebP) — `testing`
6. Test large batch compression (10+ photos) — `testing`
7. Verify Dark Mode colors across all screens — `testing`
8. Test iCloud photos compression (download + save back) — `testing`
9. Record demo video and embed on website — `marketing`
10. Activate App Store links and Smart App Banner at launch — `marketing`
11. Set up Google Search Console and analytics — `marketing`
12. Product Hunt launch — `marketing`
13. Community outreach: Reddit, Hacker News, Indie Hackers — `marketing`
14. Contact iOS blogs for reviews — `marketing`
15. Run competitor analysis — `marketing`
16. App Store localization (DA, DE, FR, JA) — `marketing`, `enhancement`

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
- **Subtitle:** "Compress Photos on iPhone"
- **Keywords:** `compress photos,reduce photo size,free up space,photo compressor,shrink photos,strip metadata,HEIC compress,photo optimizer,save storage,offline photos`
- **Primary Category:** Photo & Video
- **Secondary Category:** Utilities
- **Copyright:** 2026 IAMJARL

## Common tasks

**Add a metadata category**: Add property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress()`. Format-specific logic in `compressWithDestination` (JPEG/WebP/HEIC) and `compressPNG`.

**Add a new step**: Add case to `AppStep`, add view in `ContentView.swift`, update step indicator.

**Change error messages**: Edit `TrimrPixError` — all user-facing error strings are there.
