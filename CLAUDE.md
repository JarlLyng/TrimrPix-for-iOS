# CLAUDE.md — TrimrPix for iOS

Project context for developers and AI assistants working on this codebase.

## What is TrimrPix?

TrimrPix for iOS compresses photos from the user's Photos library in-place. One job: make files smaller. No cloud, no accounts, no internet required for core functionality.

## Tech stack

- **Swift** / **iOS 26.2+** / **SwiftUI**
- **PhotosUI** — `PhotosPicker` for image selection
- **Photos** — `PHPhotoLibrary` + `PHContentEditingOutput` for in-place replacement
- **ImageIO / Core Graphics** — compression, metadata processing
- **Sentry** — crash and performance monitoring (SPM, static framework)
- **IAMJARLDesignTokens** — design system (SPM, from github.com/JarlLyng/iamjarl-design)

## Architecture

MVVM with step-based navigation. Single ViewModel drives the entire flow.

```
Views (SwiftUI)  →  ImageOptimizationViewModel (@Observable, @MainActor)  →  CompressionService (nonisolated, Sendable)  →  Models (Sendable value types)
```

### App flow (AppStep enum)

`selectPhotos` → `configure` → `confirm` → `compressing` → `result`

### Key files

| File | Purpose |
|------|---------|
| `TrimrPix_for_iOSApp.swift` | Entry point, Sentry init |
| `ContentView.swift` | All 5 step views (SelectPhotos, Configure, Confirm, Compressing, Result) |
| `ViewModels/ImageOptimizationViewModel.swift` | All state, photo loading, compression orchestration, Photos library replacement |
| `Services/CompressionService.swift` | JPEG/PNG/WebP/HEIC compression via ImageIO, metadata stripping |
| `Services/ColorQuantizer.swift` | Median-cut color quantization for lossy PNG |
| `Models/MetadataStrippingOptions.swift` | Granular metadata control (keep/strip per category) |
| `Models/ImageItem.swift` | Per-image state (original data, compressed size, thumbnail, errors) |
| `Models/CompressionQuality.swift` | Same (0.95) / Good (0.80) / Smaller (0.60) |
| `Models/OutputFormat.swift` | JPEG, PNG, WebP, HEIC |
| `Models/TrimrPixError.swift` | All error types |
| `Views/SlideToConfirmView.swift` | Drag gesture confirmation (85% threshold) |

## Concurrency model

- ViewModel is `@MainActor` (project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- `CompressionService` is `nonisolated` + `Sendable` — safe to call from detached tasks
- Compression runs in `Task.detached(priority: .userInitiated)` to keep UI responsive
- `compress()` spawns a fire-and-forget `Task` stored in `compressionTask` (supports cancellation)
- `replaceInPhotosLibrary` uses `withCheckedThrowingContinuation` to bridge callback-based `requestContentEditingInput`

## Secrets

`Secrets.swift` is gitignored. Copy from `Secrets.swift.template` and fill in:
- `sentryDSN` — Sentry DSN string
- `sentryAuthToken` — for dSYM upload build phase
- `sentryOrg` — Sentry organization slug
- `sentryProject` — Sentry project slug

Sentry auth token is also stored in `Sentry.xcconfig` (gitignored) as `SENTRY_AUTH_TOKEN` for the build phase script.

## Build notes

- **dSYM upload**: Release builds run a "Upload dSYMs to Sentry" build phase using sentry-cli
- **Sandbox disabled on Release**: `ENABLE_USER_SCRIPT_SANDBOXING = NO` on Release config for sentry-cli network access
- **"Upload Symbols Failed" warning**: Expected — Sentry's static framework via SPM doesn't include dSYMs in the archive. Harmless; sentry-cli handles your app's dSYMs separately
- **Package update**: After pulling, run File → Packages → Resolve Package Versions in Xcode

## Design system

Uses `IAMJARLDesignTokens` from the `iamjarl-design` SPM package. All colors are mode-aware (light/dark) via `DesignTokens.Common.*` with a `colorScheme` parameter. Typography, spacing, and radius tokens are also from this package.

## Privacy

- `NSPhotoLibraryUsageDescription` set in build settings
- `PrivacyInfo.xcprivacy` declares crash data + performance data collection (Sentry)
- No tracking, no third-party analytics beyond Sentry
- Photos are processed entirely on-device

## Common tasks

**Add a new metadata category**: Add a property to `MetadataStrippingOptions`, update `processedProperties(from:)`, add entry to `labels` array.

**Change compression behavior**: Edit `CompressionService.compress()`. Format-specific logic is in `compressWithDestination` (JPEG/WebP/HEIC) and `compressPNG`.

**Add a new step**: Add case to `AppStep` enum, add view in `ContentView.swift`, update step indicator if needed.
