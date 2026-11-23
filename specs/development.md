# TrimrPix for iOS — development

How to build the app, and how the marketing site is built and deployed. The product behaviour is
in [spec.md](spec.md), the code structure in [architecture.md](architecture.md).

## Setup

1. Copy `TrimrPix for iOS/Secrets.swift.template` to `Secrets.swift` and fill in the Sentry values.
2. Create `Sentry.xcconfig` with `SENTRY_AUTH_TOKEN = <token>`, which the dSYM upload build phase
   reads (`scripts/upload-dsyms.sh`). It needs sentry-cli:
   `brew install getsentry/tools/sentry-cli`.
3. In Xcode, File, Packages, Resolve Package Versions.

Both files are gitignored, and neither ever belongs in the repository.

**The token is a credential, so treat it like one.** Never paste it into a command you run, a
settings file, a shell alias or a commit message. A command you ran once with the token inline can
outlive the moment: in your shell history, in a tool's saved configuration, in a transcript. If it
has been exposed, rotate it in Sentry rather than only deleting the copy you can see.

## Building and testing

The app builds and runs from Xcode with no extra steps once the two files above exist. Tests live
in `TrimrPix for iOSTests` and run with Product, Test.

Two build warnings are expected and harmless:

- **"Upload Symbols Failed"** appears because Sentry ships as a static framework through SPM.
- The sandbox is turned off for Release builds, so sentry-cli can reach the network to upload
  dSYMs. Xcode Cloud runs `ci_scripts/ci_post_clone.sh` before the build.

## Where a change goes

- **Compression behaviour:** `CompressionService.compress(data:mode:format:)`. Whether a photo is
  compressed at all is decided earlier, in `replaceInPhotosLibrary`, before anything is written.
- **A metadata category:** add the property to `MetadataStrippingOptions`, update
  `processedProperties(from:)`, add the entry to `labels`.
- **A step:** a case in `AppStep`, a view in `ContentView.swift`, an entry in the step indicator.
- **An error message:** every user-facing error string is in `TrimrPixError`.
- **A new Swift file:** nothing to do in the project file, the target uses a synchronized root
  group.

## The marketing site

`docs/` is the published website, served by GitHub Pages at
[trimrpixforios.iamjarl.com](https://trimrpixforios.iamjarl.com). Anything placed there is public
the moment it is merged, so development notes belong in `specs/`, not in `docs/`.

It deploys through `.github/workflows/deploy-pages.yml` on every push to `main` that touches
`docs/`, and can be run by hand. The Pages source is GitHub Actions, not the legacy branch build
(#70). There is no Jekyll step, so files are served exactly as they are committed.

**Sitemap dates are generated, never written.** The deploy sets each `<lastmod>` in
`docs/sitemap.xml` from the last commit that touched that page, using `tools/date_sitemap.py`.
Never hand-write one: it would be overwritten, and a date that is not true is worse than no date.
A URL in the sitemap with no file behind it fails the deploy.

**The design system is served from the site's own origin,** one release copied into
`docs/assets/iamjarl-design@vX.Y.Z/`, never from a CDN and never from Google Fonts. The site
therefore makes no third-party request (#70, #61).

To move to a new release, run that tag's own script rather than copying files by hand:

```
node vendor.mjs vX.Y.Z --root docs
```

It copies only what the pages actually load, verifies each file against the hashes published with
the tag, repoints every page, and removes the previous copy. `--check` reports without changing
anything. Headings and the wordmark use the identity's display face from that copy; body copy uses
the system UI face, `--ij-font-ui`.
