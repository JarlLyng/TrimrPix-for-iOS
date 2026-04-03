# TrimrPix for iOS — Opgaver

## Åbent (test og polish)

- [ ] Test med JPEG, PNG, HEIC, WebP
- [ ] Store batches (mange billeder)
- [ ] Slide-to-confirm og annullering
- [ ] Metadata-toggles (behold dato, fjern GPS m.m.)
- [ ] Fejlhåndtering: ingen fotoadgang, komprimeringsfejl
- [ ] Hukommelse ved store batches
- [ ] Dark mode

## Leveret (reference)

Kernen er implementeret: modeller (`CompressionQuality`, `OutputFormat`, `ImageItem`, `MetadataStrippingOptions`, `TrimrPixError`), `CompressionService` + `ColorQuantizer`, `ImageOptimizationViewModel` (flow, estimering, progress, in-place erstatning), SwiftUI-steps, Fotos-rettigheder, Sentry via `Secrets.swift`-mønster, IAMJARL Design System via SPM, `PrivacyInfo.xcprivacy`, app-navn TrimrPix.
