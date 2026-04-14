# TrimrPix for iOS — Opgaver

## Åbent

- [ ] Test med JPEG, PNG, HEIC, WebP — bekræft alle formater virker korrekt
- [ ] Store batches (10+ billeder) — hukommelse og performance
- [ ] Dark mode — bekræft at alle farver ser korrekte ud
- [ ] Test på ældre enheder (iPhone SE, ældre iPads)
- [ ] Bekræft iCloud-fotos kan komprimeres (kræver netværk)

## Leveret

- [x] Kernemodeller og services (portet fra macOS)
- [x] SwiftUI step-baseret UI med alle 5 trin
- [x] Slide-to-confirm gesture med haptic feedback + annullering
- [x] Granulære metadata-toggles med "keep"-semantik og forklarende tekst
- [x] Estimering opdateres ved ændring af kvalitet, format og metadata
- [x] Resultatskærm med succes/delvis/fejlet + pr-billede fejlliste
- [x] Fire-and-forget compression task (freeze-fix)
- [x] PHAsset.fetchAssets flyttet til baggrundstråd (UI-blokering fix)
- [x] iCloud-support (`isNetworkAccessAllowed = true`)
- [x] Fotos-rettigheder: `.authorized` + `.limited` accepteres
- [x] "Open Settings" alert ved manglende fotoadgang
- [x] Photos framework-fejl mappes til brugervenlige beskeder
- [x] App Store review-prompt efter succesfuld komprimering
- [x] Asset ID fallback (strip `/L0/001` suffix)
- [x] Hukommelsesfrigivelse efter hvert billede
- [x] Sentry: crash-rapportering, app hang tracking, dSYM upload, session tracking
- [x] IAMJARL Design System via SPM (v0.1.4)
- [x] `PrivacyInfo.xcprivacy`, `Secrets.swift`-mønster
- [x] CLAUDE.md og dokumentation
