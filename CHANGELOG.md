# Changelog

All notable changes to TrimrPix for iOS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.4] — 2026-09

### Changed
- **Now runs on iOS 17 and later**, down from iOS 26.2. The old requirement was an Xcode default that nothing in the code needed, and it excluded most iPhones from installing the app at all. Verified end-to-end on iOS 18.2.

### Fixed
- The "will be removed" note under each metadata toggle showed in English on Danish, German, French and Japanese devices. The translations existed but were never looked up.

## [1.3] — 2026-08

### Added
- **Custom target size** — in Target size mode you can now enter any size instead of only the 500 KB / 1 MB / 2 MB / 5 MB presets, so you can hit an exact upload limit.

### Changed
- The App Store review prompt now waits until you've had a few successful compressions (rather than asking on your very first run), so it lands after the app has proven useful.

## [1.2] — 2026-07

### Added
- **Localization** — Danish, German, French, and Japanese (in addition to English).
- **Savings in megabytes** — the estimate now shows the absolute size alongside the percentage (e.g. ~45% · ~180 MB).
- **Lifetime savings counter** — the result screen shows the total space you've saved across all runs. Stored locally on the device, never transmitted.

### Internal
- Unit tests for the core compression, quantization, and metadata services.

## [1.1] — 2026-06

### Added
- **Target-size mode** — pick a per-photo byte budget (500 KB / 1 MB / 2 MB / 5 MB); the app binary-searches quality (JPEG/HEIC/WebP) or palette size (PNG) to fit.

### Changed
- More reliable in-place replacement, including a fallback path for pristine HEIC (HDR gain map / spatial data) that iOS refuses to edit in place.
- Lower memory use on large batches (photos are loaded one at a time).
- Quality levels now differentiate PNG output (Same / Good / Smaller).
- New app icon.

### Fixed
- Privacy & security hardening: crash reports no longer capture screenshots; the Sentry auth token is no longer compiled into the app binary.

## [1.0] — 2026-04

- Initial release: in-place photo compression for the iOS Photos library, quality presets, granular metadata control, JPEG/PNG/WebP/HEIC, fully offline.
