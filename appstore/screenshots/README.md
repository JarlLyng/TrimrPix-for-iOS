# App Store screenshots

Captured from the shipping build in the simulator. These are the files to upload in App Store
Connect; the site's copies in `docs/` are resized from the same captures.

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
