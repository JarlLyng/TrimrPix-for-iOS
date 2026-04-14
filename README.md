# TrimrPix for iOS

Compress photos from your iOS Photos library in-place. One job: make files smaller.

**Website:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com) · **macOS version:** [trimrpix.iamjarl.com](https://trimrpix.iamjarl.com)

## Features

- **Select & compress** — pick photos, choose quality and format, slide to confirm
- **In-place replacement** — originals are replaced directly, no duplicates
- **4 formats** — JPEG, PNG, WebP, HEIC
- **3 quality levels** — Same (minimal loss), Good (balanced), Smaller (aggressive)
- **Metadata control** — keep or strip date/time, GPS, camera settings, IPTC, Apple data
- **Savings estimate** — see how much space you'll save before compressing
- **iCloud support** — works with photos stored in iCloud
- **Fully offline** — no cloud, no accounts, no internet required

## Requirements

- iOS 26.2+
- Photos library access (full or limited)

## Setup

1. Clone the repo
2. Copy `TrimrPix for iOS/Secrets.swift.template` → `Secrets.swift` and fill in Sentry values
3. Create `Sentry.xcconfig` in the project root with `SENTRY_AUTH_TOKEN = <your-token>`
4. Open `TrimrPix for iOS.xcodeproj` in Xcode
5. File → Packages → Resolve Package Versions
6. Build and run

## Tech stack

Swift · SwiftUI · PhotosUI · Photos · ImageIO · StoreKit · [Sentry](https://sentry.io) · [IAMJARLDesignTokens](https://github.com/JarlLyng/iamjarl-design)

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — project context for developers and AI assistants
- [`docs/spec.md`](docs/spec.md) — product specification
- [`docs/architecture.md`](docs/architecture.md) — technical architecture

## License

Private — all rights reserved.
