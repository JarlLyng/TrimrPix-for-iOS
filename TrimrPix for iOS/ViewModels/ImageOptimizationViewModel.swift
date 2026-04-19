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

// MARK: - ViewModel

@MainActor
@Observable
final class ImageOptimizationViewModel {

    // MARK: - State

    var currentStep: AppStep = .selectPhotos
    var images: [ImageItem] = []
    var selectedPhotos: [PhotosPickerItem] = []
    var quality: CompressionQuality = .good
    var format: OutputFormat = .jpeg
    var metadataOptions: MetadataStrippingOptions = MetadataStrippingOptions()

    var isLoadingImages = false
    var isCompressing = false
    var isEstimating = false
    var wasCancelled = false

    var compressionProgress: Double = 0
    var currentImageIndex: Int = 0

    var estimatedTotalSavingsPercentage: Int = 0
    var errorMessage: String?
    var showPhotosAccessAlert = false

    // MARK: - Dependencies

    private let compressionService = CompressionService()
    private var compressionTask: Task<Void, Never>?

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
        errorMessage = nil

        var newImages: [ImageItem] = []

        for item in selectedPhotos {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    continue
                }
                let assetId = item.itemIdentifier ?? UUID().uuidString
                let imageItem = ImageItem(assetIdentifier: assetId, data: data)
                newImages.append(imageItem)
            } catch {
                // Skip images that fail to load
            }
        }

        images = newImages
        selectedPhotos = []
        isLoadingImages = false
    }

    // MARK: - Estimation

    func estimateSavings() async {
        guard hasImages else {
            estimatedTotalSavingsPercentage = 0
            return
        }

        isEstimating = true

        let imagesToEstimate = images
        let currentQuality = quality
        let currentFormat = format
        let currentMetadata = metadataOptions
        let service = compressionService

        let (totalOriginal, totalEstimated) = await Task.detached(priority: .userInitiated) {
            var original: Int64 = 0
            var estimated: Int64 = 0
            for image in imagesToEstimate {
                guard let data = image.originalData else { continue }
                original += image.originalSize
                estimated += service.estimateCompressedSize(
                    data: data, quality: currentQuality, format: currentFormat, metadataOptions: currentMetadata
                )
            }
            return (original, estimated)
        }.value

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
        errorMessage = nil

        let service = compressionService
        let currentQuality = quality
        let currentFormat = format
        let currentMetadata = metadataOptions

        compressionTask = Task {
            // Yield to let SwiftUI render the compressing step before heavy work
            try? await Task.sleep(for: .milliseconds(50))

            for i in images.indices {
                if Task.isCancelled { break }

                currentImageIndex = i
                images[i].isCompressing = true

                do {
                    guard let originalData = images[i].originalData else {
                        throw TrimrPixError.invalidImageData
                    }

                    // Compress + replace in one step. replaceInPhotosLibrary
                    // determines the actual format from the Photos-framework
                    // rendered URL (which Photos requires to match the asset's
                    // original format — mismatch → PHPhotosErrorInvalidResource
                    // 3302 on commit) and compresses to that format, not the
                    // user's chosen format. For in-place replacement the user's
                    // format choice has to yield; format conversion would
                    // require creating a new asset.
                    let compressedSize = try await replaceInPhotosLibrary(
                        assetIdentifier: images[i].assetIdentifier,
                        originalData: originalData,
                        service: service,
                        quality: currentQuality,
                        userFormat: currentFormat,
                        metadataOptions: currentMetadata
                    )

                    if Task.isCancelled { break }

                    images[i].compressedSize = compressedSize
                    images[i].releaseData()
                    images[i].isCompressed = true
                } catch {
                    if !Task.isCancelled {
                        let trimrError = error as? TrimrPixError ?? .unknown(underlyingError: error)
                        images[i].error = trimrError
                        // Send the real underlying error to Sentry so we can
                        // diagnose why individual photos fail. The UI only
                        // shows the localized description, which loses detail.
                        Self.reportPhotoError(trimrError, assetIdentifier: images[i].assetIdentifier)
                    }
                }

                // Defensive: ensure data is released even on error path
                images[i].releaseData()
                images[i].isCompressing = false
                compressionProgress = Double(i + 1) / Double(images.count)
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
    /// Returns the size of the compressed data actually written.
    private func replaceInPhotosLibrary(
        assetIdentifier: String,
        originalData: Data,
        service: CompressionService,
        quality: CompressionQuality,
        userFormat: OutputFormat,
        metadataOptions: MetadataStrippingOptions
    ) async throws -> Int64 {
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

        // Resolve the actual output format from the rendered URL's extension.
        // Photos sets this based on the asset's original resource type (e.g.
        // `.heic` for HEIC originals). Writing JPEG bytes to a `.heic` URL
        // produces PHPhotosErrorInvalidResource (3302) on commit.
        let urlExtension = output.renderedContentURL.pathExtension
        let resolvedFormat = OutputFormat.from(pathExtension: urlExtension) ?? userFormat
        Self.breadcrumb("replace.format_resolved", data: [
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
        } catch {
            let nsError = error as NSError
            // Pull everything we can out of userInfo — Photos sometimes
            // populates NSLocalizedFailureReason, NSUnderlyingError, or a
            // stack of NSMultipleUnderlyingErrorsKey entries that contain
            // the actual reason for rejection.
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
            throw TrimrPixError.assetReplaceFailed(underlyingError: error)
        }

        Self.breadcrumb("replace.done", data: ["compressedBytes": compressedData.count])
        return Int64(compressedData.count)
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
        quality = .good
        format = .jpeg
        metadataOptions = MetadataStrippingOptions()
        isLoadingImages = false
        isCompressing = false
        isEstimating = false
        wasCancelled = false
        compressionProgress = 0
        currentImageIndex = 0
        estimatedTotalSavingsPercentage = 0
        errorMessage = nil
        showPhotosAccessAlert = false
    }
}
