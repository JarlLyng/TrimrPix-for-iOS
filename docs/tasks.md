# TrimrPix for iOS — Opgaver

## Fase 1: Dokumentation
- [x] Opret `docs/spec.md`
- [x] Opret `docs/architecture.md`
- [x] Opret `docs/tasks.md`

## Fase 2: Models
- [x] `CompressionQuality` enum (Same, Good, Smaller)
- [x] `OutputFormat` enum (JPEG, PNG, WebP, HEIC)
- [x] `ImageItem` model (thumbnail, stoerrelse, PHAsset-ref, memory management)
- [x] `TrimrPixError` fejltyper
- [x] `MetadataStrippingOptions` med granulaer EXIF-kontrol

## Fase 3: Services (port fra macOS)
- [x] `CompressionService` — tilpas til iOS (Data in/out, selektiv metadata)
- [x] `ColorQuantizer` — port direkte

## Fase 4: ViewModel
- [x] `ImageOptimizationViewModel` — step-baseret flow
- [x] Estimeret besparelse (beregn foer komprimering, off-main-thread)
- [x] Progress-tracking med cirkulaer progress
- [x] In-place foto-erstatning via PHContentEditingOutput
- [x] Memory management (frigør data efter komprimering)

## Fase 5: Views (SwiftUI, step-baseret)
- [x] Step 1: `SelectPhotosStep` — PhotosPicker, billedtaeller
- [x] Step 2: `ConfigureStep` — kvalitet, format, metadata, estimering
- [x] Step 3: `ConfirmStep` — slide-to-confirm, opsummering
- [x] Step 4a: `CompressingStep` — cirkulaer progress
- [x] Step 4b: `ResultStep` — succes/fejl/delvist, per-billede fejlvisning
- [x] `SlideToConfirmView` — haptic feedback, snap-back animation

## Fase 6: Fotos-integration
- [x] `PHPhotoLibrary` content editing (in-place erstatning)
- [x] `NSPhotoLibraryUsageDescription` i build settings

## Fase 7: Infrastruktur
- [x] Sentry crash reporting (DSN via xcconfig, ikke hardcoded)
- [x] IAMJARL Design System (SPM)
- [x] `PrivacyInfo.xcprivacy`
- [x] `.gitignore` med Secrets.xcconfig
- [x] App display name: "TrimrPix"
- [x] AccentColor (mode-aware: magenta/lime)

## Fase 8: Test & Polish
- [ ] Test med forskellige billedformater (JPEG, PNG, HEIC, WebP)
- [ ] Test batch-komprimering (mange billeder)
- [ ] Test slide-to-confirm og annullering
- [ ] Test metadata-toggles (behold dato, fjern GPS)
- [ ] Fejlhaandtering (ingen adgang til fotos, komprimering fejler)
- [ ] Test memory usage ved store batches
- [ ] Test dark mode
