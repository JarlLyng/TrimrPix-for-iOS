# TrimrPix for iOS — Teknisk Arkitektur

## Overblik

SwiftUI-app med MVVM-arkitektur og step-baseret brugerflow. Kernelogik portet fra macOS-versionen, UI bygget fra bunden til iOS.

## Teknologier

- **Swift 5.0+** / iOS 26.2+
- **SwiftUI** — UI framework
- **PhotosUI** — `PhotosPicker` til billedvalg
- **Photos** — `PHPhotoLibrary` + content editing til in-place erstatning
- **Core Image / ImageIO** — Billedkomprimering
- **Sentry** — Crash reporting og performance monitoring
- **IAMJARLDesignTokens** — Design system (farver, typografi, spacing, radius)

## Arkitektur (MVVM)

```
Views (SwiftUI, step-baseret)
    |  bindings
ViewModel (@Observable, @MainActor)
    |  calls
Services (nonisolated, Sendable)
    |  uses
Models (nonisolated, Sendable value types)
```

## Brugerflow (4 steps)

1. **SelectPhotosStep** — Vaelg billeder fra Fotos via PhotosPicker
2. **ConfigureStep** — Kvalitet, format, metadata-indstillinger, estimeret besparelse
3. **ConfirmStep** — Slide-to-confirm, opsummering, advarsel om erstatning
4. **CompressingStep** → **ResultStep** — Cirkulaer progress, derefter resultater med fejlvisning

## Filstruktur

```
TrimrPix for iOS/
  TrimrPix_for_iOSApp.swift          — App entry point, Sentry init
  ContentView.swift                   — Alle steps (SelectPhotos, Configure, Confirm, Compressing, Result)
  Models/
    CompressionQuality.swift          — Same/Good/Smaller enum
    OutputFormat.swift                — JPEG/PNG/WebP/HEIC enum
    ImageItem.swift                   — Billedmodel med thumbnail og memory management
    MetadataStrippingOptions.swift    — Granulær metadata-kontrol (dato, EXIF, GPS, IPTC, Apple)
    TrimrPixError.swift               — Fejltyper
  ViewModels/
    ImageOptimizationViewModel.swift  — Koordinerer flow, komprimering og Photos-integration
  Views/
    SlideToConfirmView.swift          — Slide-to-confirm gesture-komponent
  Services/
    CompressionService.swift          — Format-specifik komprimering med selektiv metadata-stripping
    ColorQuantizer.swift              — Median-cut PNG farve-reduktion
```

## Nøglebeslutninger

- **In-place foto-erstatning** via `PHContentEditingOutput` — ingen create+delete, ingen dubletter
- **Detached tasks** for komprimering — holder UI responsivt
- **Memory management** — `originalData` frigøres efter hvert billede er komprimeret
- **Granulær metadata** — brugeren kan beholde dato/tid mens GPS fjernes
- **Sentry DSN** via xcconfig/Info.plist — ikke hardcoded i kode
