# iamjarl-design v1.11.0 — served from this site

A copy of the two files this site loads from the design system, served from our
own origin instead of a CDN. Owner's decision, 2026-10-15
(JarlLyng/iamjarl-design#102, recorded on #67): jsDelivr's `/gh/` path answered
`503 No healthy backends` or timed out for minutes on 2026-10-14 and 15. A
`tokens.css` that stalls leaves the page without its colours; an `ij-footer.js`
that stalls leaves an empty element where the footer should be.

Self-hosting also closes a second hole. These were loaded from a third party
with no `integrity` attribute, so a substituted `ij-footer.js` would simply have
been executed. Both files are now pinned to the hashes below (see #65).

## What is here

| File | sha384 |
|------|--------|
| `dist/css/tokens.css` | `tRpvcOTDD7ybqs2bDjvmA5z6EqQwOXNPf9QWNaKq4HXLfjkkQpzdZ14sDLffoHTN` |
| `dist/components/ij-footer.js` | `aTSJ9Z75tCUyCsmDazVC1dLzmCAUYPh+lSH9Y1fIkp8e1FJ0jX7XV8y4zgFLPYub` |

Both were taken from the `v1.11.0` tag and verified against that tag's
`dist/sri.json`, kept here beside them. They were also checked byte-for-byte
against what jsDelivr was serving at the time of the copy: identical, so this
changed availability and trust, not appearance.

Neither file reaches the network at runtime. `tokens.css` has no `@import` and
no `url()`, so no fonts ride along, and `ij-footer.js` carries the cross-link
list as data rather than fetching it. These two files are the whole dependency.

`LICENSE` is the design system's own (MIT). It travels with the copy because
redistribution requires it.

## Re-making this folder

From a checkout of `JarlLyng/iamjarl-design` at the tag:

```sh
git show v1.11.0:dist/css/tokens.css          > dist/css/tokens.css
git show v1.11.0:dist/components/ij-footer.js > dist/components/ij-footer.js
git show v1.11.0:dist/sri.json                > sri.json
git show v1.11.0:LICENSE                      > LICENSE
```

Then check each file against `sri.json` before linking it, and put the same
`integrity` value on the tag in the HTML.

## Upgrading

Do not edit these files. A new version means a new folder named for its tag,
new hashes from that tag's `sri.json`, and the links updated to match. The site
redesign (#67) moves to v1.32.2, which adds the kit, the identity sheet, the
nav, and two font families — each face's own licence has to travel with its
`woff2` under OFL-1.1.
