# TrimrPix for iOS — Teknisk arkitektur

Produktkrav og brugeroplevelse: [spec.md](spec.md).

## MVVM

```
Views (SwiftUI)
    → bindings →
ViewModel (@Observable, @MainActor)
    → kald →
Services (nonisolated, Sendable)
    → bruger →
Models (Sendable value types)
```

**ViewModel** (`ImageOptimizationViewModel`) ejer al tilstand og orkestrerer flowet. Der er kun én ViewModel i appen.

**Services** (`CompressionService`, `ColorQuantizer`) er `nonisolated` og `Sendable` — de kan kaldes fra detached tasks uden actor-isolation-konflikter.

**Models** er simple value types: `ImageItem`, `CompressionQuality`, `OutputFormat`, `MetadataStrippingOptions`, `TrimrPixError`.

## App-tilstande (`AppStep`)

`selectPhotos` → `configure` → `confirm` → `compressing` → `result`

Step-indikatoren i header viser fire segmenter; `compressing` og `result` deler det sidste (samme `index`).

SwiftUI-views (alle i `ContentView.swift`): **SelectPhotosStep**, **ConfigureStep**, **ConfirmStep**, **CompressingStep**, **ResultStep**. **SlideToConfirmView** bruges på bekræftelsessteget med 85% drag-threshold.

## Concurrency-model

- Projektet bruger `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — alt er main actor-isoleret medmindre eksplicit markeret `nonisolated`
- ViewModel er `@MainActor @Observable`
- `CompressionService` er `nonisolated final class: Sendable`
- Tung komprimering kører i `Task.detached(priority: .userInitiated)` for at holde UI responsivt
- `compress()` spawner en fire-and-forget `Task` gemt i `compressionTask` (understøtter annullering via `Task.isCancelled`)
- `PHAsset.fetchAssets` kører i `Task.detached` for at undgå at blokere main actor
- `replaceInPhotosLibrary` wrapper callback-baseret `requestContentEditingInput` i `withCheckedThrowingContinuation`

## Fotos-rettigheder

`PhotosPicker` kræver **ingen** rettigheder — Apple håndterer det out-of-process. Men **skrivning** til biblioteket kræver `.readWrite` adgang:

- `.authorized` og `.limited` accepteres begge
- `.notDetermined` → system-dialog vises automatisk
- `.denied` → appen viser en alert med "Open Settings" knap
- Tjekkes i `ensurePhotosWriteAccess()` FØR komprimering starter

## Komprimeringsflow

1. Bruger swiper slide-to-confirm
2. `ensurePhotosWriteAccess()` tjekker rettigheder (alert hvis afvist)
3. UI skifter til CompressingStep
4. For hvert billede:
   a. Komprimer data i `Task.detached` via `CompressionService`
   b. Find PHAsset i `Task.detached` (undgår at blokere UI)
   c. `requestContentEditingInput` med `isNetworkAccessAllowed = true` (iCloud-support)
   d. Erstat original via `PHContentEditingOutput` + `performChanges`
   e. Frigiv `originalData` for at spare hukommelse
5. Ved fejl: fejlen gemmes pr. billede som `TrimrPixError`
6. Resultatskærm viser succes/delvis/fejlet + besparelse
7. Ved fuld succes: `requestReview()` beder om App Store-anmeldelse

## Metadata-håndtering

`MetadataStrippingOptions` styrer granulær metadata-stripping med "keep"-semantik:

| Toggle | Standard | Hvad den dækker |
|--------|----------|-----------------|
| `keepDateTime` | true | EXIF dato/tid, TIFF DateTime |
| `keepCameraSettings` | false | EXIF (eksponering, ISO, blænde m.m.), TIFF (kameramodel) |
| `keepGPS` | false | GPS-dictionary |
| `keepIPTC` | false | Copyright, billedbeskrivelse, nøgleord |
| `keepAppleMaker` | false | Live Photo, HDR, burst-info |

`processedProperties(from:)` filtrerer metadata selektivt fra `CGImageSource`.

## Fejlhåndtering

Alle fejl mappes til `TrimrPixError` for brugervenlige beskeder:

- Photos framework-fejl → `assetReplaceFailed` ("Failed to replace photo in library")
- Asset ikke fundet → `assetNotFound` ("Photo not found in library")
- Komprimering fejlet → `compressionFailed` (formatspecifik besked)
- Adgang nægtet → alert med "Open Settings" (når ikke til resultatskærmen)

## Nøglebeslutninger

- **In-place erstatning** via `PHContentEditingOutput` — ingen create+delete, ingen dubletter
- **Fire-and-forget compression task** — `compress()` returnerer hurtigt; komprimering kører i baggrunds-task med cancellation-support
- **Hukommelse** — `originalData` frigives efter hvert behandlet billede; thumbnails beholdes til UI
- **Estimering** — kører fuld komprimering i detached task for at give præcis estimering
- **iCloud** — `isNetworkAccessAllowed = true` på `requestContentEditingInput` så fotos i iCloud kan redigeres
