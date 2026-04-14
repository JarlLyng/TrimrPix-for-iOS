# CLAUDE.md — TrimrPix for iOS

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## What is TrimrPix?

iOS app that compresses photos from the user's Photos library in-place. One job: make files smaller. No cloud, no accounts, no internet required.

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

## Common tasks

**Add a metadata category**: Add property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress()`. Format-specific logic in `compressWithDestination` (JPEG/WebP/HEIC) and `compressPNG`.

**Add a new step**: Add case to `AppStep`, add view in `ContentView.swift`, update step indicator.

**Change error messages**: Edit `TrimrPixError` — all user-facing error strings are there.
