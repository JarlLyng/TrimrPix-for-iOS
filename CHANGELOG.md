# Changelog

All notable changes to TrimrPix for iOS are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/).

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
