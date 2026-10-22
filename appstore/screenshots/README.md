# App Store screenshots

Two stages. `raw/` (iPhone) and `raw-ipad/` hold the plain simulator captures; `6.9-inch/`,
`6.3-inch/` and `13-inch-ipad/` hold the composed posters, and those are what gets uploaded.

Composition uses the hub's `tools/appstore_screenshots.py`, which puts the screen on the brand
ground with a caption and reads the accent from the design system. An uncaptioned UI shot asks
the shopper to work out what they are looking at, which is the standard in `DESIGN.md`.

```
tools/appstore_screenshots.py compose raw/4-result.png "Smaller photos, *no duplicate album*" \
  6.9-inch/1.png --slot iphone-6.9 --mode light
tools/appstore_screenshots.py compose raw/4-result.png "Smaller photos, *no duplicate album*" \
  6.3-inch/1.png --slot iphone-6.3 --mode light
tools/appstore_screenshots.py compose raw-ipad/4-result.png "Smaller photos, *no duplicate album*" \
  13-inch-ipad/1.png --slot ipad-13 --mode light
```

The 6.3" and iPad sets use the same captions in the same order. The 6.3" set differs from the
6.9" only in `--slot`.

`*phrase*` renders in the accent colour. Mode follows the app, which is light.

## Order, and why

`DESIGN.md`: order by proof, not by feature tour, and the first frame carries most of the
decision.

1. **Result**, "Smaller photos, *no duplicate album*". The claim that is uniquely true here.
2. **Configure**, "Hit an *exact file size*". The differentiator against every other compressor.
3. **Confirm**, "*Nothing changes* until you confirm". Removes the biggest objection, that this
   is irreversible.
4. **Select**, "Pay once. *No subscription.*" Position four is for the minority still looking.

**Keep the set telling one story.** All four frames are one run: three photos, 5.9 MB, 1 MB
target, an estimate of ~50% / ~2.9 MB, and 3.5 MB saved. The iPad set is the same run on the
iPad. A first pass for 1.5 had 500 KB in one frame and 1 MB in the next, which a shopper
comparing them would notice.

The site's copies in `docs/` are resized from the same raw captures, not from the posters.

| | |
|---|---|
| Device | iPhone 17 Pro Max, 1320 × 2868; iPad Pro 13-inch (M5), 2064 × 2752 |
| Slot | iPhone 6.9" and 6.3", both from the same raw captures (App Store Connect requires the 6.3" set, iPhone with Dynamic Island medium display, since 1.5.1: #80), and iPad 13 inch |
| Captured | 2026-10-21, from the final 1.5.1 build, iOS 26.5 simulator |
| Appearance | Light, English, status bar overridden to 9:41 with full battery and signal |

## From the next version: the site's light identity

The owner's decision of 2026-10-22, for both TrimrPix apps: from the next version, the posters
take the site's light identity. The 1.5.1 set above keeps the tool's default light ground and the
design system's accent, and is not recomposed; the posters change with the next version.

- Ground `#F1F0F6`, caption text `#1C1B22`.
- Olive `#4A5900` for the accent text (`*phrase*`) and the tick above the caption.
- Lime `#D0FF00` only as a chip behind black text (`[phrase]`), never as text on the light ground.
  A chip never wraps, so keep its phrase short: "[no duplicate album]" runs off the 6.3" poster.

Top-level manifest keys for `tools/appstore_screenshots.py batch`, next to `shots` (the `chip` key
was added to the hub tool on 2026-10-22):

```json
{
  "mode": "light", "ground": "#F1F0F6", "text": "#1C1B22",
  "accent": "#4A5900", "chip": "#D0FF00", "chip_text": "#000000"
}
```

For a single `compose`, the same values are `--mode light --ground "#F1F0F6" --text "#1C1B22"
--accent "#4A5900" --chip "#D0FF00" --chip-text "#000000"`.

## Recapturing

The screens are the four steps: select, configure (Target size, **1 MB**, the same target as
the social card and the site's hero line), confirm, result.

Use a fresh simulator, so the library holds only the stock sample photos and the lifetime
counter starts at zero. Pick three JPEGs: the misty waterfall, the flower in the grass and the
leaves. Leave out the pink flowers: that one is HEIC, and in the simulator it takes the
delete-and-recreate path, which adds a Replaced row and a confirmation sheet to the run.

Set the simulator's own language and region to English before the captures, or the status bar
formats the time (and the iPad's date) in the Mac's locale: `xcrun simctl spawn $SIM defaults
write -g AppleLanguages -array en`, the same for `AppleLocale en_US`, then reboot the simulator.

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
