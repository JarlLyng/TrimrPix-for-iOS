# TrimrPix for iOS — Opgaver

## Åbent (test og polish)

- [ ] Test med JPEG, PNG, HEIC, WebP — bekræft alle formater virker korrekt
- [ ] Store batches (10+ billeder) — hukommelse og performance
- [ ] Dark mode — bekræft at alle farver ser korrekte ud
- [ ] Test på ældre enheder (iPhone SE, ældre iPads)

## Leveret

- [x] Kernemodeller: `CompressionQuality`, `OutputFormat`, `ImageItem`, `MetadataStrippingOptions`, `TrimrPixError`
- [x] `CompressionService` + `ColorQuantizer` (portet fra macOS)
- [x] `ImageOptimizationViewModel` — flow, estimering, progress, in-place erstatning
- [x] SwiftUI step-baseret UI med alle 5 trin
- [x] Fotos-rettigheder (`.readWrite` adgang, fejlhåndtering)
- [x] Slide-to-confirm gesture med haptic feedback
- [x] Annullering af komprimering
- [x] Granulære metadata-toggles med "keep"-semantik og forklarende tekst
- [x] Estimering opdateres ved ændring af kvalitet, format og metadata
- [x] Resultatskærm med succes/delvis/fejlet tilstande + pr-billede fejlliste
- [x] Sentry integration: crash-rapportering, dSYM upload, app version tagging
- [x] `Secrets.swift`-mønster (gitignoreret, template committed)
- [x] IAMJARL Design System via SPM
- [x] `PrivacyInfo.xcprivacy` med Sentry data-deklarationer
- [x] App-navn: TrimrPix, UI på engelsk
- [x] Fire-and-forget compression task (freeze-fix)
- [x] Hukommelsesfrigivelse efter hvert billede
- [x] Asset ID fallback (strip `/L0/001` suffix)
- [x] CLAUDE.md og opdateret dokumentation
