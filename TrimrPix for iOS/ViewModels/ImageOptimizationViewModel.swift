//
//  ImageOptimizationViewModel.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import Foundation
import SwiftUI
import PhotosUI
import Photos
import Sentry

// MARK: - Replace outcome

/// Result of trying to replace a photo. `inPlace` means the change committed
/// immediately via `PHContentEditingOutput`; `needsFallback` means Photos
/// rejected the in-place commit (typically pristine HEIC with HDR gain map
/// or spatial stereo on iOS 26) and the caller should batch this photo's
/// compressed bytes with other fallbacks for a single create-new-and-delete
/// transaction at the end of the batch — keeping user-facing deletion
/// confirmation prompts down to one per run rather than one per photo.
nonisolated enum ReplaceOutcome: Sendable {
    case inPlace(size: Int64)
    case needsFallback(compressedData: Data, tempURL: URL, size: Int64)
}

/// State accumulated during the compression loop for photos that need the
/// create-new-and-delete fallback. Held until the loop finishes, then
/// committed in a single `PHPhotoLibrary.performChanges` transaction so
/// the user sees exactly one iOS deletion confirmation sheet.
private struct PendingFallback {
    let imageIndex: Int
    let asset: PHAsset
    let tempURL: URL
    let size: Int64
}

// MARK: - Step

nonisolated enum AppStep: Sendable {
    case selectPhotos
    case configure
    case confirm
    case compressing
    case result

    var index: Int {
        switch self {
        case .selectPhotos: return 0
        case .configure: return 1
        case .confirm: return 2
        case .compressing, .result: return 3
        }
    }
}

// MARK: - Preferences

/// Lightweight UserDefaults-backed store for the user's last-used settings.
/// Only quality and metadata persist; `format` is not user-selectable (#30).
/// Declared in the app's privacy policy as locally stored, never transmitted.
private enum Preferences {
    private static let qualityKey = "preferences.quality"
    private static let metadataKey = "preferences.metadataOptions"

    static var quality: CompressionQuality {
        get {
            guard let raw = UserDefaults.standard.string(forKey: qualityKey),
                  let value = CompressionQuality(rawValue: raw) else {
                return .good
            }
            return value
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: qualityKey) }
    }

    static var metadataOptions: MetadataStrippingOptions {
        get {
            guard let data = UserDefaults.standard.data(forKey: metadataKey),
                  let value = try? JSONDecoder().decode(MetadataStrippingOptions.self, from: data) else {
                return MetadataStrippingOptions()
            }
            return value
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: metadataKey)
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class ImageOptimizationViewModel {

    // MARK: - State

    var currentStep: AppStep = .selectPhotos
    var images: [ImageItem] = []
    var selectedPhotos: [PhotosPickerItem] = []

    /// Quality and metadata choices persist across launches and "Start over"
    /// (see `Preferences`). `format` is not user-selectable — in-place
    /// replacement always keeps the asset's original format (see #30) — so it
    /// stays at its default and is only a last-resort fallback in
    /// `replaceInPhotosLibrary`.
    var quality: CompressionQuality = .good {
        didSet { Preferences.quality = quality }
    }
    var format: OutputFormat = .jpeg
    var metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions() {
        didSet { Preferences.metadataOptions = metadataOptions }
    }

    var isLoadingImages = false
    var isCompressing = false
    var isEstimating = false
    var wasCancelled = false

    var compressionProgress: Double = 0
    var currentImageIndex: Int = 0

    var estimatedTotalSavingsPercentage: Int = 0
    var showPhotosAccessAlert = false

    // MARK: - Dependencies

    private let compressionService = CompressionService()
    private var compressionTask: Task<Void, Never>?
    private var estimateTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        // Restore the user's last-used quality and metadata choices.
        quality = Preferences.quality
        metadataOptions = Preferences.metadataOptions
    }

    // MARK: - Computed

    var totalOriginalSize: Int64 {
        images.reduce(0) { $0 + $1.originalSize }
    }

    var hasImages: Bool {
        !images.isEmpty
    }

    var canCompress: Bool {
        hasImages && !isCompressing && !isLoadingImages
    }

    // MARK: - Photo Loading

    func loadSelectedPhotos() async {
        guard !selectedPhotos.isEmpty else { return }

        isLoadingImages = true

        var newImages: [ImageItem] = []

        for item in selectedPhotos {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    continue
                }
                let assetId = item.itemIdentifier ?? UUID().uuidString
                // `data` is consumed by the initializer (size + thumbnail) and
                // released at the end of this iteration — never accumulated.
                let imageItem = ImageItem(pickerItem: item, assetIdentifier: assetId, data: data)
                newImages.append(imageItem)
            } catch {
                // Skip images that fail to load
            }
        }

        images = newImages
        selectedPhotos = []
        isLoadingImages = false
    }

    /// Reload a photo's original bytes on demand. Used by the estimate and
    /// compression loops so only one photo's data is resident at a time (#25).
    private func loadOriginalData(for item: PhotosPickerItem) async -> Data? {
        try? await item.loadTransferable(type: Data.self)
    }

    // MARK: - Estimation

    /// Cancel any in-flight estimate and start a fresh one. Quality/metadata
    /// toggles fire in quick succession; without cancellation a slower earlier
    /// run could finish last and overwrite the result with a stale value (#34).
    func scheduleEstimate() {
        estimateTask?.cancel()
        estimateTask = Task { await estimateSavings() }
    }

    func estimateSavings() async {
        guard hasImages else {
            estimatedTotalSavingsPercentage = 0
            return
        }

        isEstimating = true

        let currentQuality = quality
        let currentFormat = format
        let currentMetadata = metadataOptions
        let service = compressionService

        // Load and estimate one photo at a time so only a single photo's bytes
        // are resident at once (#25). Each iteration's `data` is released before
        // the next load.
        var totalOriginal: Int64 = 0
        var totalEstimated: Int64 = 0
        for image in images {
            if Task.isCancelled { return }
            guard let data = await loadOriginalData(for: image.pickerItem) else { continue }
            totalOriginal += image.originalSize
            totalEstimated += await Task.detached(priority: .userInitiated) {
                service.estimateCompressedSize(
                    data: data, quality: currentQuality, format: currentFormat, metadataOptions: currentMetadata
                )
            }.value
        }

        // A newer estimate superseded this one — let it own the result and the
        // isEstimating flag rather than writing a stale value.
        if Task.isCancelled { return }

        if totalOriginal > 0 {
            let savings = Double(totalOriginal - totalEstimated) / Double(totalOriginal) * 100
            estimatedTotalSavingsPercentage = max(0, Int(savings.rounded()))
        } else {
            estimatedTotalSavingsPercentage = 0
        }

        isEstimating = false
    }

    // MARK: - Photos Authorization

    private func ensurePhotosWriteAccess() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            // Both full and limited access allow editing user-selected photos
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus != .authorized && newStatus != .limited {
                throw TrimrPixError.photosAccessDenied
            }
        default:
            throw TrimrPixError.photosAccessDenied
        }
    }

    // MARK: - Compression

    func compress() async {
        // Ensure we have write access before showing progress
        do {
            try await ensurePhotosWriteAccess()
        } catch {
            // Show alert prompting user to grant access in Settings
            showPhotosAccessAlert = true
            return
        }

        // Permission granted — show compressing step
        withAnimation(AccessibilityAnimation.default) { currentStep = .compressing }
        isCompressing = true
        wasCancelled = false
        compressionProgress = 0
        currentImageIndex = 0

        let service = compressionService
        let currentQuality = quality
        let currentFormat = format
        let currentMetadata = metadataOptions

        compressionTask = Task {
            try? await Task.sleep(for: .milliseconds(50))

            var pendingFallbacks: [PendingFallback] = []

            for i in images.indices {
                if Task.isCancelled { break }

                currentImageIndex = i
                images[i].isCompressing = true

                do {
                    // Load this photo's bytes only now, just before we need
                    // them; they're released at the end of the iteration (#25).
                    guard let originalData = await loadOriginalData(for: images[i].pickerItem) else {
                        throw TrimrPixError.invalidImageData
                    }

                    let outcome = try await replaceInPhotosLibrary(
                        assetIdentifier: images[i].assetIdentifier,
                        originalData: originalData,
                        service: service,
                        quality: currentQuality,
                        userFormat: currentFormat,
                        metadataOptions: currentMetadata
                    )

                    if Task.isCancelled { break }

                    switch outcome {
                    case .inPlace(let size):
                        images[i].compressedSize = size
                        images[i].wasReplaced = false
                        images[i].isCompressed = true
                    case .needsFallback(_, let tempURL, let size):
                        // Defer marking compressed until the batch fallback
                        // transaction commits at end of loop. Photos requires
                        // the PHAsset for the final performChanges, so fetch
                        // it now while we're still iterating.
                        if let asset = try? await Self.fetchAsset(identifier: images[i].assetIdentifier) {
                            pendingFallbacks.append(PendingFallback(
                                imageIndex: i,
                                asset: asset,
                                tempURL: tempURL,
                                size: size
                            ))
                        } else {
                            try? FileManager.default.removeItem(at: tempURL)
                            images[i].error = .assetNotFound(images[i].assetIdentifier)
                        }
                    }
                } catch {
                    if !Task.isCancelled {
                        let trimrError = error as? TrimrPixError ?? .unknown(underlyingError: error)
                        images[i].error = trimrError
                        Self.reportPhotoError(trimrError, assetIdentifier: images[i].assetIdentifier)
                    }
                }

                images[i].isCompressing = false
                compressionProgress = Double(i + 1) / Double(images.count)
            }

            // Batch-commit all fallbacks in a single performChanges so iOS
            // only asks the user to confirm deletion once for the whole run.
            if !pendingFallbacks.isEmpty && !Task.isCancelled {
                await commitPendingFallbacks(pendingFallbacks)
            } else {
                // Either cancelled or no fallbacks — clean up any temp files
                // we would otherwise leak.
                for fallback in pendingFallbacks {
                    try? FileManager.default.removeItem(at: fallback.tempURL)
                }
            }

            isCompressing = false
            compressionTask = nil
            withAnimation(AccessibilityAnimation.default) { currentStep = .result }
        }

    }

    func cancelCompression() {
        wasCancelled = true
        compressionTask?.cancel()
    }

    // MARK: - Photos Library

    /// Compress `originalData` and replace the asset in the Photos library
    /// in place. The compression format is determined by the asset's original
    /// format (read from `PHContentEditingOutput.renderedContentURL`), not by
    /// `userFormat` — Photos rejects commits where the rendered file's format
    /// doesn't match the asset (`PHPhotosErrorInvalidResource`, code 3302).
    ///
    /// Returns a `ReplaceOutcome` indicating whether the replacement was done
    /// truly in-place or via the copy-and-delete fallback, and the final size.
    private func replaceInPhotosLibrary(
        assetIdentifier: String,
        originalData: Data,
        service: CompressionService,
        quality: CompressionQuality,
        userFormat: OutputFormat,
        metadataOptions: MetadataStrippingOptions
    ) async throws -> ReplaceOutcome {
        Self.breadcrumb("replace.start", data: [
            "asset": assetIdentifier,
            "originalBytes": originalData.count,
            "userFormat": "\(userFormat)"
        ])

        // Fetch asset off the main actor to avoid blocking UI
        let asset: PHAsset = try await Task.detached {
            // Try direct fetch first
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            if let found = fetchResult.firstObject { return found }

            // PhotosPickerItem.itemIdentifier may include /L0/001 suffix — strip it
            let baseId = assetIdentifier.components(separatedBy: "/").first ?? assetIdentifier
            let retryResult = PHAsset.fetchAssets(withLocalIdentifiers: [baseId], options: nil)
            if let found = retryResult.firstObject { return found }

            throw TrimrPixError.assetNotFound(assetIdentifier)
        }.value

        // Inspect all resources attached to the asset. Live Photos carry both
        // a `photo` and a `pairedVideo` resource; Portrait mode adds depth;
        // Spatial photos embed two images. If we only write a still image but
        // Photos is expecting multiple resources, the commit is rejected with
        // PHPhotosErrorInvalidResource (3302).
        let resources = PHAssetResource.assetResources(for: asset)
        let resourceSummary = resources.map { r -> String in
            "type=\(r.type.rawValue) uti=\(r.uniformTypeIdentifier)"
        }

        Self.breadcrumb("replace.asset_fetched", data: [
            "mediaType": asset.mediaType.rawValue,
            "mediaSubtypes": asset.mediaSubtypes.rawValue,
            "sourceType": asset.sourceType.rawValue,
            "canEdit": asset.canPerform(.content),
            "resources": resourceSummary,
            "resourceCount": resources.count
        ])

        // Allow iCloud downloads so we can edit photos not stored locally
        let editOptions = PHContentEditingInputRequestOptions()
        editOptions.isNetworkAccessAllowed = true

        // Declare that we can handle *any* prior adjustment data. Without this
        // Photos rejects commits on photos that have existing edits (from
        // Apple Photos editor, other apps, or our own previous TrimrPix runs)
        // with PHPhotosErrorInvalidResource (3302). We rewrite the entire
        // image content anyway, so we don't actually need to interpret the
        // prior adjustment — we just need to claim compatibility so Photos
        // lets us start a new edit chain on top.
        editOptions.canHandleAdjustmentData = { _ in true }

        // Request content editing input to modify asset in-place
        let input = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PHContentEditingInput, Error>) in
            asset.requestContentEditingInput(with: editOptions) { input, info in
                if let input {
                    continuation.resume(returning: input)
                } else {
                    // info dictionary contains PHContentEditingInputErrorKey,
                    // PHContentEditingInputCancelledKey, etc. — capture for diagnosis.
                    let underlying = info[PHContentEditingInputErrorKey] as? Error
                    Self.breadcrumb("replace.edit_input_failed", level: .error, data: [
                        "info_keys": info.keys.map { "\($0)" },
                        "cancelled": info[PHContentEditingInputCancelledKey] as? Bool ?? false,
                        "error": underlying.map { "\($0)" } ?? "nil"
                    ])
                    continuation.resume(throwing: TrimrPixError.assetReplaceFailed(underlyingError: underlying))
                }
            }
        }

        Self.breadcrumb("replace.edit_input_ok", data: [
            "hasAdjustmentData": input.adjustmentData != nil,
            "adjustmentFormat": input.adjustmentData?.formatIdentifier ?? "none",
            "adjustmentVersion": input.adjustmentData?.formatVersion ?? "none"
        ])

        // Create editing output with compressed data
        let output = PHContentEditingOutput(contentEditingInput: input)

        // Resolve the target format from the original asset's photo resource
        // UTI, NOT from renderedContentURL.pathExtension. Photos sometimes
        // hands us a `.JPG` URL even when the underlying asset is HEIC or PNG
        // (an artifact of how content-editing inputs are prepared). If we
        // trust the URL extension and write JPEG bytes, commit fails with
        // PHPhotosErrorInvalidResource (3302) because validation checks
        // against the original resource's UTI.
        //
        // Falls back to URL extension then to userFormat if we can't find a
        // primary photo resource (extremely unlikely for `mediaType == .image`).
        let primaryResourceUTI = resources.first(where: { $0.type == .photo })?.uniformTypeIdentifier
        let urlExtension = output.renderedContentURL.pathExtension
        let resolvedFormat = OutputFormat.from(uti: primaryResourceUTI ?? "")
            ?? OutputFormat.from(pathExtension: urlExtension)
            ?? userFormat
        Self.breadcrumb("replace.format_resolved", data: [
            "primaryResourceUTI": primaryResourceUTI ?? "none",
            "urlExtension": urlExtension,
            "userFormat": "\(userFormat)",
            "resolvedFormat": "\(resolvedFormat)",
            "overridden": resolvedFormat != userFormat
        ])

        // Compress to the format Photos expects. autoreleasepool keeps
        // Core Graphics / ImageIO transient objects from accumulating.
        let compressedData = try await Task.detached(priority: .userInitiated) {
            try autoreleasepool {
                try service.compress(
                    data: originalData,
                    quality: quality,
                    format: resolvedFormat,
                    metadataOptions: metadataOptions
                )
            }
        }.value

        do {
            try compressedData.write(to: output.renderedContentURL)
        } catch {
            Self.breadcrumb("replace.write_failed", level: .error, data: ["error": "\(error)"])
            throw TrimrPixError.assetReplaceFailed(underlyingError: error)
        }

        Self.breadcrumb("replace.wrote_bytes", data: ["bytes": compressedData.count])

        // Mark the edit with an adjustment data identifier
        let adjustmentData = PHAdjustmentData(
            formatIdentifier: "com.iamjarl.TrimrPix",
            formatVersion: "1.0",
            data: Data("compressed".utf8)
        )
        output.adjustmentData = adjustmentData

        // Apply the edit in-place — no create+delete, no duplicates
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest(for: asset)
                request.contentEditingOutput = output
            }
            Self.breadcrumb("replace.done", data: ["compressedBytes": compressedData.count])
            return .inPlace(size: Int64(compressedData.count))
        } catch {
            let nsError = error as NSError
            var userInfoDump: [String: String] = [:]
            for (key, value) in nsError.userInfo {
                userInfoDump["\(key)"] = "\(value)".prefix(300).description
            }
            let underlyings = (nsError.userInfo["NSMultipleUnderlyingErrorsKey"] as? [Error]) ?? []
            Self.breadcrumb("replace.perform_changes_failed", level: .error, data: [
                "domain": nsError.domain,
                "code": nsError.code,
                "localizedDescription": nsError.localizedDescription,
                "localizedFailureReason": nsError.localizedFailureReason ?? "nil",
                "userInfo": userInfoDump,
                "underlyingCount": underlyings.count,
                "underlyings": underlyings.prefix(3).map { "\($0)".prefix(300).description }
            ])

            // Only fall back for PHPhotosErrorInvalidResource (3302). Other
            // errors (permission, I/O, user-cancel) should propagate so the
            // user sees a real failure rather than a silent copy.
            let isInvalidResource = nsError.domain == "PHPhotosErrorDomain" && nsError.code == 3302
            guard isInvalidResource else {
                throw TrimrPixError.assetReplaceFailed(underlyingError: error)
            }

            // Write compressed bytes to a temp file for the later batch
            // fallback transaction. We don't commit here — the caller
            // accumulates all fallbacks and commits them in a single
            // performChanges so iOS shows one deletion confirmation sheet.
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(resolvedFormat.fileExtension)
            do {
                try compressedData.write(to: tempURL)
            } catch {
                Self.breadcrumb("replace.fallback_write_failed", level: .error, data: ["error": "\(error)"])
                throw TrimrPixError.assetReplaceFailed(underlyingError: error)
            }

            Self.breadcrumb("replace.fallback_queued", data: [
                "reason": "PHPhotosErrorInvalidResource",
                "tempURL": tempURL.lastPathComponent,
                "bytes": compressedData.count
            ])
            return .needsFallback(
                compressedData: compressedData,
                tempURL: tempURL,
                size: Int64(compressedData.count)
            )
        }
    }

    /// Commit all queued fallback photos (create-new + delete-old) in a single
    /// `performChanges` transaction. iOS shows exactly one deletion
    /// confirmation sheet for the whole batch, regardless of how many photos
    /// are being replaced. If the user declines, every queued photo is marked
    /// as errored; if they accept, every queued photo is marked compressed
    /// with `wasReplaced = true`.
    private func commitPendingFallbacks(_ fallbacks: [PendingFallback]) async {
        Self.breadcrumb("fallback.batch_commit_start", data: ["count": fallbacks.count])

        do {
            try await PHPhotoLibrary.shared().performChanges {
                for fallback in fallbacks {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let resourceOptions = PHAssetResourceCreationOptions()
                    creationRequest.addResource(with: .photo, fileURL: fallback.tempURL, options: resourceOptions)
                    // Preserve metadata that affects sort order and UX.
                    // Keywords/description aren't readable via PHAsset public API.
                    creationRequest.creationDate = fallback.asset.creationDate
                    creationRequest.location = fallback.asset.location
                    creationRequest.isFavorite = fallback.asset.isFavorite
                }
                let assetsToDelete = fallbacks.map(\.asset) as NSArray
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            }

            Self.breadcrumb("fallback.batch_commit_done", data: ["count": fallbacks.count])

            for fallback in fallbacks {
                images[fallback.imageIndex].compressedSize = fallback.size
                images[fallback.imageIndex].wasReplaced = true
                images[fallback.imageIndex].isCompressed = true
            }
        } catch {
            let nsError = error as NSError
            Self.breadcrumb("fallback.batch_commit_failed", level: .error, data: [
                "domain": nsError.domain,
                "code": nsError.code,
                "description": nsError.localizedDescription,
                "count": fallbacks.count
            ])

            // User declined the deletion confirmation, or Photos failed to
            // commit for some other reason. Mark everything as errored so the
            // user sees what didn't work rather than silent loss.
            let fallbackError = TrimrPixError.assetReplaceFailed(underlyingError: error)
            for fallback in fallbacks {
                images[fallback.imageIndex].error = fallbackError
                Self.reportPhotoError(fallbackError, assetIdentifier: images[fallback.imageIndex].assetIdentifier)
            }
        }

        // Temp files either became assets (Photos owns the data now) or
        // will never be used — either way clean up our tmp dir entries.
        for fallback in fallbacks {
            try? FileManager.default.removeItem(at: fallback.tempURL)
        }
    }

    /// Fetch a PHAsset by local identifier on a background thread, with the
    /// same /L0/001-suffix retry we do in `replaceInPhotosLibrary`. Exposed
    /// as a static helper so we can call it outside a replace cycle.
    private static func fetchAsset(identifier: String) async throws -> PHAsset {
        try await Task.detached {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            if let found = fetchResult.firstObject { return found }

            let baseId = identifier.components(separatedBy: "/").first ?? identifier
            let retryResult = PHAsset.fetchAssets(withLocalIdentifiers: [baseId], options: nil)
            if let found = retryResult.firstObject { return found }

            throw TrimrPixError.assetNotFound(identifier)
        }.value
    }

    // MARK: - Sentry helpers

    private static func breadcrumb(_ message: String, level: SentryLevel = .info, data: [String: Any] = [:]) {
        let crumb = Breadcrumb(level: level, category: "compression")
        crumb.message = message
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }

    private static func reportPhotoError(_ error: TrimrPixError, assetIdentifier: String) {
        // Build an NSError with the underlying cause so Sentry groups sensibly
        // and we keep full domain/code info from the Photos framework.
        let underlying: Error? = {
            switch error {
            case .assetReplaceFailed(let u), .compressionFailed(_, let u),
                 .imageLoadFailed(let u), .unknown(let u):
                return u
            default:
                return nil
            }
        }()

        let reportable = underlying ?? error
        SentrySDK.capture(error: reportable) { scope in
            scope.setTag(value: "compression", key: "feature")
            scope.setTag(value: "\(error)", key: "trimrpix_error")
            scope.setContext(value: [
                "asset_identifier": assetIdentifier,
                "trimrpix_error_case": "\(error)",
                "localized": error.localizedDescription,
                "underlying": underlying.map { "\($0)" } ?? "nil"
            ], key: "photo_compression")
        }
    }

    // MARK: - Reset

    func reset() {
        compressionTask?.cancel()
        compressionTask = nil
        currentStep = .selectPhotos
        images = []
        selectedPhotos = []
        // Quality and metadata are deliberately preserved across "Start over"
        // and "Compress more" — they're user preferences, not per-batch state.
        isLoadingImages = false
        isCompressing = false
        isEstimating = false
        wasCancelled = false
        compressionProgress = 0
        currentImageIndex = 0
        estimatedTotalSavingsPercentage = 0
        showPhotosAccessAlert = false
    }
}
