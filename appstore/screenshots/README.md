# App Store screenshots

Two stages. `raw/` holds the plain simulator captures; `6.9-inch/` holds the composed posters,
and those are what gets uploaded.

Composition uses the hub's `tools/appstore_screenshots.py`, which puts the screen on the brand
ground with a caption and reads the accent from the design system. An uncaptioned UI shot asks
the shopper to work out what they are looking at, which is the standard in `DESIGN.md`.

```
tools/appstore_screenshots.py compose raw/4-result.png "Smaller photos, *no duplicate album*" \
  6.9-inch/1.png --slot iphone-6.9 --mode light
```

`*phrase*` renders in the accent colour. Mode follows the app, which is light.

## Order, and why

`DESIGN.md`: order by proof, not by feature tour, and the first frame carries most of the
decision.

1. **Result**, "Smaller photos, *no duplicate album*". The claim that is uniquely true here.
2. **Configure**, "Hit an *exact file size*". The differentiator against every other compressor.
3. **Confirm**, "*Nothing changes* until you confirm". Removes the biggest objection, that this
   is irreversible.
4. **Select**, "Pay once. *No subscription.*" Position four is for the minority still looking.

**Keep the set telling one story.** Frames 2 and 3 are from the same run: three photos, 4 MB,
1 MB target, ~43% / ~1.7 MB. A first pass had 500 KB in one frame and 1 MB in the next, which a
shopper comparing them would notice.

The site's copies in `docs/` are resized from the same raw captures, not from the posters.

| | |
|---|---|
| Device | iPhone 17 Pro Max, 1320 × 2868 |
| Slot | 6.9 inch. Apple scales this down for the smaller slots, so it is the only size needed. |
| Appearance | Light, English, status bar overridden to 9:41 with full battery and signal |

## Recapturing

The screens are the four steps: select, configure (Target size, **1 MB**, so the figures agree
with the social card and the site's hero line), confirm, result.

```
SIM=<udid>
xcrun simctl ui $SIM appearance light
xcrun simctl ui $SIM content_size large
xcrun simctl status_bar $SIM override --time "9:41" --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3
xcrun simctl launch $SIM com.iamjarl.TrimrPix-for-iOS -AppleLanguages "(en-US)" -AppleLocale en_US
xcrun simctl io $SIM screenshot <name>.png
```

**Recapture whenever the UI changes.** These are version metadata in App Store Connect, so a stale
set can only be replaced with a version submission. The 1.1 set survived three releases showing a
format picker the app no longer had.
