# Contributing to TrimrPix for iOS

Thanks for your interest. TrimrPix for iOS is a solo indie project — I (Jarl) build it for myself and ship what makes the app better. That shapes how this repo accepts contributions.

## What I welcome

- **Bug reports.** Open an [issue](https://github.com/JarlLyng/TrimrPix-for-iOS/issues) with steps to reproduce, expected vs. actual behavior, and the device/iOS version. Anonymous Sentry stack traces help a lot.
- **Feature requests.** Open an issue. I read everything, but the bar for adding features is intentionally high — see "Design philosophy" below.
- **Documentation fixes.** Typos, broken links, outdated examples — PRs welcome and almost always merged.
- **Forks.** This app is **AGPL-3.0**: you may fork and ship your own version, but derivatives must stay open source under AGPL-3.0 (including network-served use). If you build something cool, I'd love to hear about it.

## What's a harder sell

- **Large feature PRs without a prior issue discussion.** Open an issue first so we can talk about whether it fits the wedge.
- **Refactors that don't fix a concrete bug or unblock a feature.** The codebase is intentionally small.
- **New third-party dependencies.** Sentry (anonymous crash reporting) and the IAMJARL design tokens are the only ones. Adding deps requires a strong case.

## Design philosophy

TrimrPix for iOS is deliberately focused. The wedge is "the iPhone photo compressor that replaces the original **in place** — no duplicate album — for one honest price, nothing tracked."

Strengthens the wedge:
- More reliable in-place replacement
- Better metadata control (keep date, strip GPS, etc.)
- Better accessibility and localization
- Clearer single-task UI

Weakens the wedge (likely declined):
- A user-facing **format picker** (forces every photo through create-and-delete, defeating in-place — see CLAUDE.md)
- "Compress my whole library" / background automation
- A Share Extension (it can't do true in-place — gets copies; deliberately not built)
- Accounts, sign-in, cloud sync, subscriptions, IAP, or ads

If unsure whether something fits, open an issue and ask before writing code.

## Code style

- SwiftUI; iOS 26.2+.
- Use `iamjarl-design` tokens — no hardcoded colors/spacing/radius/type.
- Localize UI strings (`Text("…")` / `String(localized:)`); see `Localizable.xcstrings`.
- Privacy-first: nothing leaves the device except opt-in anonymous crash reports.
