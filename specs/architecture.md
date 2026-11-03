# TrimrPix for iOS — technical architecture

Product requirements and user experience: [spec.md](spec.md).

## MVVM

```
Views (SwiftUI)
    → bindings →
ViewModel (@Observable, @MainActor)
    → calls →
Services (nonisolated, Sendable)
    → uses →
Models (Sendable value types)
```

**ViewModel** (`ImageOptimizationViewModel`) owns all state and orchestrates the flow. There is only one ViewModel in the app.

**Services** (`CompressionService`, `ColorQuantizer`) are `nonisolated` and `Sendable` — they can be called from detached tasks without actor-isolation conflicts.

**Models** are plain value types: `ImageItem`, `CompressionQuality`, `OutputFormat`, `MetadataStrippingOptions`, `SkipReason`, `TrimrPixError`.

## App steps (`AppStep`)

`selectPhotos` → `configure` → `confirm` → `compressing` → `result`

The step indicator in the header shows four segments; `compressing` and `result` share the last one (same `index`).

The SwiftUI views (all in `ContentView.swift`): **SelectPhotosStep**, **ConfigureStep**, **ConfirmStep**, **CompressingStep**, **ResultStep**. **SlideToConfirmView** is used on the confirm step with an 85% drag threshold.

## Concurrency model

- The project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — everything is main-actor isolated unless explicitly marked `nonisolated`
- The ViewModel is `@MainActor @Observable`
- `CompressionService` is a `nonisolated final class: Sendable`
- Heavy compression runs in `Task.detached(priority: .userInitiated)` to keep the UI responsive
- `compress()` spawns a fire-and-forget `Task` held in `compressionTask` (supports cancellation via `Task.isCancelled`)
- `PHAsset.fetchAssets` runs in a `Task.detached` to avoid blocking the main actor
- `replaceInPhotosLibrary` wraps the callback-based `requestContentEditingInput` in `withCheckedThrowingContinuation`

## Photos permissions

`PhotosPicker` needs **no** permission — Apple handles it out of process. But **writing** to the library needs `.readWrite` access:

- `.authorized` and `.limited` are both accepted
- `.notDetermined` → the system dialog appears automatically
- `.denied` → the app shows an alert with an "Open Settings" button
- Checked in `ensurePhotosWriteAccess()` BEFORE compression starts

## Compression flow

1. The user swipes slide-to-confirm
2. `ensurePhotosWriteAccess()` checks permissions (alert if denied)
3. The UI switches to CompressingStep
4. For each photo:
   a. `formatSkipReason` on the picker's bytes — a format that cannot be written stops here, before Photos is touched
   b. Find the `PHAsset` in a `Task.detached` (avoids blocking the UI), and read the size of its current version
   c. `targetSkipReason` on that library size — a photo already under the target stops here, before any editing input is requested
   d. Compress the data in a `Task.detached` via `CompressionService`
   e. `shrinkSkipReason` comparing the compressed bytes against the library size — a result that is not smaller stops here, before anything is written
   f. `requestContentEditingInput` with `isNetworkAccessAllowed = true` (iCloud support)
   g. Replace the original via `PHContentEditingOutput` + `performChanges`
   h. Release `originalData` to save memory
5. Photos that Photos rejects with `PHPhotosErrorInvalidResource` (3302) are queued for the fallback rather than failed (see below)
6. On error: the error is stored per photo as a `TrimrPixError`
7. The result screen shows success / partial / failed, plus skipped and the saving
8. On full success: `requestReview()` asks for an App Store review

## Replacement, and the fallback

In-place replacement via `PHContentEditingOutput` is tried first, and is what the app is for. Some photos cannot be replaced that way: Photos answers `PHPhotosErrorInvalidResource` (3302), typically for a pristine HEIC with an HDR gain map or spatial stereo data. Those are not failed. They fall back to creating a new asset from the compressed bytes — preserving creation date, location and favourite — and deleting the original (#26).

Every fallback photo in a batch is committed in a single `performChanges` transaction, so the user sees exactly one iOS deletion confirmation sheet however many photos took that path. See `replaceInPhotosLibrary` and `commitPendingFallbacks`.

The fallback is why "no duplicates" holds while "cannot be undone" does not: the original of an in-place edit is kept by Photos and can be reverted, and a fallback original sits in Recently Deleted for 30 days. It is also why compressing frees no space until Recently Deleted is emptied, and why an in-place edit frees none at all (#79).

## Metadata handling

`MetadataStrippingOptions` drives granular metadata stripping with "keep" semantics:

| Toggle | Default | What it covers |
|--------|---------|----------------|
| `keepDateTime` | true | EXIF date/time, TIFF DateTime |
| `keepCameraSettings` | false | EXIF (exposure, ISO, aperture and so on), TIFF (camera model) |
| `keepGPS` | false | The GPS dictionary |
| `keepIPTC` | false | Copyright, caption, keywords |
| `keepAppleMaker` | false | Live Photo, HDR, burst info |

`processedProperties(from:)` filters metadata selectively from the `CGImageSource`.

A skipped photo is never written, so it keeps all of its metadata regardless of these toggles.

## Error handling

Every error is mapped to `TrimrPixError` for readable messages:

- Photos framework error → `assetReplaceFailed` ("Failed to replace photo in library")
- Asset not found → `assetNotFound` ("Photo not found in library")
- Compression failed → `compressionFailed` (format-specific message)
- Access denied → alert with "Open Settings" (never reaches the result screen)

A skip is not an error. `SkipReason` is a separate type and is reported on the result screen with one explanation per reason.

## Key decisions

- **In-place replacement** via `PHContentEditingOutput`, with a create-and-delete fallback only for the photos Photos refuses (3302), batched into one confirmation
- **Skip rather than fail or rewrite** — three checks decide before anything is written, each measuring against the library's photo rather than the picker's copy (#71, #74, #76, #77)
- **Fire-and-forget compression task** — `compress()` returns quickly; compression runs in a background task with cancellation support
- **Memory** — `originalData` is released after each photo; thumbnails are kept for the UI
- **Estimation** — runs a full compression in a detached task to give an accurate estimate
- **iCloud** — `isNetworkAccessAllowed = true` on `requestContentEditingInput` so photos in iCloud can be edited
