# TrimrPix for iOS — product specification

Concept, user experience and functional requirements. For how it is built: [architecture.md](architecture.md).

## Concept

TrimrPix for iOS compresses photos from the user's photo library. One job: make files smaller without needless complexity. Everything happens on the device.

## User flow

1. **Select photos**: multi-select via PhotosPicker (needs no permission). The count and total size are shown.
2. **Configure**: choose quality and metadata settings. The estimated saving updates as you go.
3. **Confirm**: a summary of the choices, and a note that the originals are replaced. Confirmed with slide-to-confirm. If photo access is missing, an alert with "Open Settings" appears.
4. **Compressing**: progress as a circular indicator (photo X of Y). Can be cancelled.
5. **Result**: how many were compressed, the total saving, the average saving. Errors are shown per photo. Photos that were left alone appear as *Skipped*, with one explanation per reason, and do not count as failures (see [Photos that are skipped](#photos-that-are-skipped)). On full success the app may ask for an App Store review.

The interface is localized: English (base), Danish, German, French and Japanese. Strings live in `TrimrPix for iOS/Localizable.xcstrings`.

## Compression modes

The user picks one of two modes in the Configure step:

- **Quality**: a fixed quality level (see below).
- **Target size**: a target file size **per photo** (500 KB / 1 MB / 2 MB / 5 MB, or a size of your own). The service binary-searches the lossy quality (JPEG/HEIC) or reduces the palette (PNG) to hit the target. Photos already at or under the target are skipped and left untouched: no re-encode and no edit in Photos. If the target cannot be hit even at the lowest quality, the smallest achievable result is used (the actual size is always shown in the result). This is a **per-photo** budget, not a total for the batch.

## Quality levels

| Level | Quality | Description | Typical saving |
|-------|---------|-------------|----------------|
| Same | 0.95 | No visible loss of quality | 5–15% |
| Good | 0.80 | Light compression, hard to tell apart | 30–50% |
| Smaller | 0.60 | More aggressive, visible when zoomed | 60–80% |

## Output format

TrimrPix compresses **JPEG**, **PNG** and **HEIC**. Each photo **keeps its original format**, and the format is not the user's to choose. That is a deliberate consequence of in-place replacement: Photos rejects a commit where the rendered photo's format does not match the asset's original resource UTI (`PHPhotosErrorInvalidResource`, 3302). Format conversion belongs to the macOS sibling app.

PNG uses median-cut colour quantization at Good and Smaller to reduce file size.

**WebP** can be read but not written: ImageIO has no WebP encoder on iOS (`CGImageDestinationCopyTypeIdentifiers()` has no WebP entry). A WebP photo is therefore skipped. The check happens at runtime (`CompressionService.canEncode`), so an iOS version that gains a WebP encoder would compress WebP with no code change.

### Photos that are skipped

Before anything is written, three checks decide whether a photo is left alone (#71): `CompressionService.formatSkipReason` on the picker's bytes, before Photos is touched at all; `CompressionService.targetSkipReason` on the size of the photo's current version in the library (`PHImageManager`, `version = .current`); and, after compressing, `CompressionService.shrinkSkipReason`, which compares the compressed result against that same library size. Not `PHContentEditingInput.fullSizeImageURL`: the app accepts any prior adjustments, so that URL points at the unedited original. The picker's bytes can be a re-encoded copy of a different size (a 1.27 MB JPEG arrived as 993 KB, a 2.8 MB HEIC as 4.1 MB), so they are not used to measure against.

`compress` already keeps the original if the result comes out larger, but it compares against the picker's copy. When that copy is larger than the library's file, the result can be smaller than the copy and still larger than the photo in the library. Without the third check, the HEIC above went through the fallback and came back at 3.0 MB.

| Reason | When | Message on the result screen |
|--------|------|------------------------------|
| `formatNotWritable` | The format can be read but not written on this device (today, WebP) | *iOS can open WebP photos but can't save them, so they were left as they are.* |
| `alreadyUnderTarget` | Target size, and the photo is already at or under the target | *Photos already under the target size were left as they are.* |
| `wouldNotShrink` | The compressed result is no smaller than the photo in the library | *Photos that wouldn't get any smaller were left as they are.* |

A skipped photo is not changed in the library. It counts neither as compressed nor as an error, and is not reported to Sentry. The estimate treats it as unchanged. Since nothing is written, a skipped photo also keeps its metadata, even where the user switched a category off.

### Where the saving is measured from

The result screen's *Space saved* and *Avg. savings*, and the lifetime total, are all counted from the photo's current version in the library, measured just before the edit (`SizeChange`, `ImageItem.librarySize`). The picker's byte count is used only when Photos cannot give a size. A photo that would not get smaller is skipped (`wouldNotShrink`) and does not count. `SizeChange` also treats a larger result as 0 saved.

The estimate and the total size in the Configure step are still counted from the picker's bytes. They are shown before the app has asked for photo access (the picker needs none), and the library's sizes cannot be read without it. The estimate can therefore be off where the picker hands over a re-encoded copy.

## Metadata

The user chooses which metadata categories are **kept** (toggle ON = keep, OFF = remove permanently). The explanatory text above the toggles: *"Choose which metadata to keep. Disabled items will be permanently removed."*

| Category | Default | Contents |
|----------|---------|----------|
| Date & time | Kept | When the photo was taken |
| Camera settings | Removed | Camera model, exposure, ISO, aperture |
| GPS location | Removed | Latitude, longitude, altitude |
| Copyright & description | Removed | Photographer, caption, keywords (IPTC) |
| Apple data | Removed | Live Photo, HDR, burst info |

## Photos access

- Picking photos via `PhotosPicker` needs **no** permission
- Compressing (writing) needs `.readWrite` access — both full and limited access work
- First time: the system dialog appears automatically
- If denied: an alert with an "Open Settings" button guides the user

## Compression and replacement

- Original photos are replaced **in place** via the Photos framework's content editing API
- No duplicates — the photo is modified directly in the library
- Compressing replaces the photo in your library, which is why the app asks you to confirm. It is not permanent destruction: Photos keeps the original of an in-place edit and offers Revert to Original, and a photo that takes the create-and-delete fallback leaves its original in Recently Deleted for 30 days. Note that this is also why compressing does not free space until Recently Deleted is emptied, and an in-place edit does not free it at all (#79)
- The estimated saving is calculated before compressing and updates when quality or metadata change
- Memory is released as the batch proceeds
- iCloud photos are supported (downloaded automatically when needed)

## Error handling

- Missing photo access → alert with "Open Settings" (blocks compression)
- Photo not found in the library → a per-photo error; the rest continue
- Compression failure → a per-photo error with a format-specific message
- A format that cannot be written (WebP), or a photo already under the target: skipped, not an error
- Replacement failed → a readable message with a recovery suggestion
- Cancellation → the partial result is shown
