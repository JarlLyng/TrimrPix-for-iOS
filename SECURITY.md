# Security Policy

## Reporting a vulnerability

If you've found a security issue in TrimrPix for iOS, please **don't open a public issue**. Email me directly:

**jarl@iamjarl.com**

Please include:
- A description of the vulnerability
- Steps to reproduce
- The affected version (App Store version or commit SHA)
- Your contact info if you'd like credit when it's fixed

I'll respond within 7 days. For confirmed issues, I'll work on a patch and ship it as quickly as the App Store review process allows (typically 1–3 days for review, plus development time).

## Scope

In scope:
- TrimrPix for iOS app code
- The marketing site at `trimrpixforios.iamjarl.com`

Out of scope:
- Third-party dependencies (Sentry, IAMJARLDesignTokens) — report to those projects directly
- Apple platform vulnerabilities — report to Apple Product Security
- Issues in forks of this repo

## What TrimrPix for iOS does and doesn't handle

TrimrPix is a single-purpose photo compressor with a deliberately small attack surface:

- **No backend.** No server, no database, no API endpoints.
- **No accounts.** No sign-up, no authentication, no password storage.
- **On-device only.** Photos are compressed in place in the Photos library; nothing is uploaded. iCloud photos are downloaded by the system, processed locally, and saved back.
- **No tracking.** The only data collection is anonymous Sentry crash reports (stack traces, device type, iOS/app version) — no personal data. The marketing site uses Umami (no cookies, no fingerprinting).
- **Photos permission only.** The app requests access to the photos you select; it does not read your library in the background.

If you find a way to break any of those guarantees, I want to know.

## Past advisories

None to date.
