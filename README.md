# TrimrPix for iOS

[![Co-created with AI](https://madebyhuman.iamjarl.com/badges/co-created-white.svg)](https://madebyhuman.iamjarl.com)

Compress photos from your iOS Photos library in-place. One job: make files smaller.

**Website:** [trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com) · **macOS version:** [trimrpix.iamjarl.com](https://trimrpix.iamjarl.com)

## Features

- **Select & compress** — pick photos, choose quality or a target size, slide to confirm
- **In-place replacement** — originals are replaced directly in your Photos library, no duplicates
- **Two modes** — quality presets (Same / Good / Smaller) or a per-photo target size (500 KB–5 MB)
- **4 formats** — JPEG, PNG, WebP, HEIC; each photo keeps its original format
- **Metadata control** — keep or strip date/time, GPS, camera settings, IPTC, Apple data
- **Savings estimate** — see how much space you'll save before compressing
- **iCloud support** — works with photos stored in iCloud
- **Localized** — English, Danish, German, French, Japanese
- **Fully offline & private** — no cloud, no accounts, no internet required

## Requirements

- iOS 26.2+
- iPhone or iPad (universal app)
- Photos library access (full or limited)

## Setup

1. Clone the repo
2. Copy `TrimrPix for iOS/Secrets.swift.template` → `Secrets.swift`. Sentry is optional — leave the DSN as the placeholder and the app simply runs without crash reporting.
3. (Optional, for crash-report dSYM upload) Create `Sentry.xcconfig` in the project root with `SENTRY_AUTH_TOKEN = <your-token>`
4. Open `TrimrPix for iOS.xcodeproj` in Xcode
5. File → Packages → Resolve Package Versions
6. Build and run

`Secrets.swift` and `Sentry.xcconfig` are gitignored and never committed.

## Tech stack

Swift · SwiftUI · PhotosUI · Photos · ImageIO · StoreKit · [Sentry](https://sentry.io) · [IAMJARLDesignTokens](https://github.com/JarlLyng/iamjarl-design)

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — project context for developers and AI assistants
- [`docs/spec.md`](docs/spec.md) — product specification
- [`docs/architecture.md`](docs/architecture.md) — technical architecture

## Roadmap

All planned work is tracked as [GitHub Issues](../../issues). Check `gh issue list` for current tasks.

## Contributing

Issues and pull requests are welcome. This is a small, focused app — if you're proposing a feature, opening an issue first to discuss fit is appreciated.

## License

Open source under the [GNU AGPL-3.0](LICENSE). You're welcome to read, learn from, and build on the code; under the AGPL, any distributed derivative must also be released under the AGPL. If you'd rather just use the app, the polished build is on the [App Store](https://apps.apple.com/app/id6761081919) for $1.99.

Copyright © 2026 Jarl Lyng / [IAMJARL](https://iamjarl.com).
