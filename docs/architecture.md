# TrimrPix for iOS — Teknisk arkitektur

Produktkrav og brugeroplevelse: [spec.md](spec.md).

## Overblik

SwiftUI-app med MVVM og step-baseret flow. Komprimeringslogik portet fra macOS; iOS-UI er bygget særskilt. Appen kører helt lokalt — ingen netværk til kernefunktionen.

## Teknologier

- **Swift** / **iOS 26.2+** (deployment target i Xcode-projektet)
- **SwiftUI** — UI
- **PhotosUI** — `PhotosPicker` til billedvalg (multi-select)
- **Photos** — `PHPhotoLibrary`, `PHContentEditingOutput` til in-place erstatning
- **Core Image / ImageIO** — komprimering og metadata-håndtering
- **Sentry** — fejl- og performanceovervågning (DSN fra `Secrets.swift`, gitignoreret)
- **IAMJARLDesignTokens** — design tokens via SPM (farver, typografi, spacing, radius)

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
- `replaceInPhotosLibrary` wrapper callback-baseret `requestContentEditingInput` i `withCheckedThrowingContinuation`
- `PHPhotoLibrary.shared().performChanges` bruges som async call til in-place billedredigering

## Komprimeringsflow

1. ViewModel tjekker `.readWrite` adgang til Photos (`ensurePhotosWriteAccess`)
2. For hvert billede:
   a. Komprimer data i detached task via `CompressionService`
   b. Erstat original i Photos via `PHContentEditingOutput` (`replaceInPhotosLibrary`)
   c. Frigiv `originalData` for at spare hukommelse (`releaseData()`)
3. Ved fejl: fejlen gemmes pr. billede i `ImageItem.error`
4. Resultatskærm viser succes/delvis/fejlet + besparelse

## Metadata-håndtering

`MetadataStrippingOptions` styrer granulær metadata-stripping med "keep"-semantik:

| Toggle | Standard | Hvad den dækker |
|--------|----------|-----------------|
| `keepDateTime` | true | EXIF dato/tid, TIFF DateTime |
| `keepCameraSettings` | false | EXIF (eksponering, ISO, blænde m.m.), TIFF (kameramodel) |
| `keepGPS` | false | GPS-dictionary |
| `keepIPTC` | false | Copyright, billedbeskrivelse, nøgleord |
| `keepAppleMaker` | false | Live Photo, HDR, burst-info |

`processedProperties(from:)` i `MetadataStrippingOptions` filtrerer metadata selektivt fra `CGImageSource`.

## Filstruktur

```
TrimrPix for iOS/
  TrimrPix_for_iOSApp.swift          — entry point, Sentry-init
  ContentView.swift                    — alle 5 step-views
  Secrets.swift.template               — skabelon; Secrets.swift er lokal og gitignoreret
  Models/
    CompressionQuality.swift           — Same (0.95) / Good (0.80) / Smaller (0.60)
    OutputFormat.swift                 — JPEG, PNG, WebP, HEIC
    ImageItem.swift                    — billede-state (data, størrelse, thumbnail, fejl)
    MetadataStrippingOptions.swift     — metadata-kontrol med selektiv EXIF-stripping
    TrimrPixError.swift                — alle fejltyper
  ViewModels/
    ImageOptimizationViewModel.swift   — al tilstand og logik
  Views/
    SlideToConfirmView.swift           — drag-gesture bekræftelse
  Services/
    CompressionService.swift           — JPEG/PNG/WebP/HEIC komprimering via ImageIO
    ColorQuantizer.swift               — median-cut farve-kvantisering til PNG
```

## Secrets og Sentry-opsætning

- `Secrets.swift` (gitignoreret) indeholder `sentryDSN`, `sentryAuthToken`, `sentryOrg`, `sentryProject`
- `Sentry.xcconfig` (gitignoreret) indeholder `SENTRY_AUTH_TOKEN` til build phase-scriptet
- Release builds kører "Upload dSYMs to Sentry" build phase via sentry-cli
- `ENABLE_USER_SCRIPT_SANDBOXING = NO` på Release for at sentry-cli kan tilgå netværk
- "Upload Symbols Failed" warning i Xcode er forventet og harmløs (Sentry's static framework via SPM inkluderer ikke dSYMs i arkivet)

## Nøglebeslutninger

- **In-place erstatning** via `PHContentEditingOutput` — ingen create+delete, ingen dubletter
- **Fire-and-forget compression task** — `compress()` returnerer hurtigt; compression kører i baggrunds-task med cancellation-support
- **Hukommelse** — `originalData` frigives efter hvert behandlet billede; thumbnails beholdes til UI
- **Estimering** — kører fuld komprimering i detached task for at give præcis estimering
- **Metadata** — brugerens toggles mappes til selektiv stripping i `CompressionService` via `MetadataStrippingOptions.processedProperties(from:)`

## Design system

Bruger `IAMJARLDesignTokens` SPM-pakke fra `github.com/JarlLyng/iamjarl-design`. Alle farver er mode-aware (lys/mørk) via `DesignTokens.Common.*` med `colorScheme`-parameter. Typografi, spacing og radius er også fra pakken.
