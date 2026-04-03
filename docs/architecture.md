# TrimrPix for iOS — Teknisk arkitektur

Produktkrav og brugeroplevelse: [spec.md](spec.md).

## Overblik

SwiftUI-app med MVVM og step-baseret flow. Komprimeringslogik portet fra macOS; iOS-UI er bygget særskilt.

## Teknologier

- **Swift 5** / **iOS 26.2+** (deployment target i Xcode-projektet)
- **SwiftUI** — UI
- **PhotosUI** — `PhotosPicker`
- **Photos** — `PHPhotoLibrary` og content editing til in-place erstatning
- **Core Image / ImageIO** — komprimering og metadata
- **Sentry** — fejl- og performanceovervågning (DSN fra `Secrets.swift`, som kopieres fra `Secrets.swift.template` og er gitignoreret)
- **IAMJARLDesignTokens** — design tokens (farver, typografi, spacing, radius)

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

## App-tilstande (`AppStep`)

`ImageOptimizationViewModel` styrer: `selectPhotos` → `configure` → `confirm` → `compressing` → `result`. Step-indikatoren i header viser fire segmenter; `compressing` og `result` deler det sidste (samme `index`).

SwiftUI-trin (i `ContentView.swift`): **SelectPhotosStep**, **ConfigureStep**, **ConfirmStep**, **CompressingStep**, **ResultStep**. **SlideToConfirmView** bruges på bekræftelsessteget.

## Filstruktur (app-mappen)

```
TrimrPix for iOS/
  TrimrPix_for_iOSApp.swift       — entry point, Sentry-init
  ContentView.swift                 — alle steps
  Secrets.swift.template          — skabelon; Secrets.swift (lokal, gitignoreret)
  Models/
    CompressionQuality.swift
    OutputFormat.swift
    ImageItem.swift
    MetadataStrippingOptions.swift
    TrimrPixError.swift
  ViewModels/
    ImageOptimizationViewModel.swift
  Views/
    SlideToConfirmView.swift
  Services/
    CompressionService.swift
    ColorQuantizer.swift
```

## Nøglebeslutninger

- **In-place erstatning** via `PHContentEditingOutput` — ingen separat create/delete for dubletter.
- **Afkoblede tasks** til komprimering — UI forbliver responsivt.
- **Hukommelse** — `originalData` frigives efter hvert behandlet billede.
- **Metadata** — brugerens toggles mappes til selektiv stripping i `CompressionService`.
