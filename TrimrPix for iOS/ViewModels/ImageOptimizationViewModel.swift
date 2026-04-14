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
        withAnimation { currentStep = .compressing }
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

                    let compressedData = try await Task.detached(priority: .userInitiated) {
                        try service.compress(data: originalData, quality: currentQuality, format: currentFormat, metadataOptions: currentMetadata)
                    }.value

                    if Task.isCancelled { break }

                    images[i].compressedSize = Int64(compressedData.count)

                    // Replace in Photos library — only mark as compressed if this succeeds
                    try await replaceInPhotosLibrary(
                        assetIdentifier: images[i].assetIdentifier,
                        compressedData: compressedData
                    )

                    images[i].isCompressed = true
                } catch {
                    if !Task.isCancelled {
                        images[i].error = error as? TrimrPixError ?? .unknown(underlyingError: error)
                    }
                }

                // Free memory — original data no longer needed
                images[i].releaseData()
                images[i].isCompressing = false
                compressionProgress = Double(i + 1) / Double(images.count)
            }

            isCompressing = false
            compressionTask = nil
            withAnimation { currentStep = .result }
        }

    }

    func cancelCompression() {
        wasCancelled = true
        compressionTask?.cancel()
    }

    // MARK: - Photos Library

    private func replaceInPhotosLibrary(assetIdentifier: String, compressedData: Data) async throws {
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

        // Allow iCloud downloads so we can edit photos not stored locally
        let editOptions = PHContentEditingInputRequestOptions()
        editOptions.isNetworkAccessAllowed = true

        // Request content editing input to modify asset in-place
        let input = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PHContentEditingInput, Error>) in
            asset.requestContentEditingInput(with: editOptions) { input, _ in
                if let input {
                    continuation.resume(returning: input)
                } else {
                    continuation.resume(throwing: TrimrPixError.assetReplaceFailed(underlyingError: nil))
                }
            }
        }

        // Create editing output with compressed data
        let output = PHContentEditingOutput(contentEditingInput: input)

        do {
            try compressedData.write(to: output.renderedContentURL)
        } catch {
            throw TrimrPixError.assetReplaceFailed(underlyingError: error)
        }

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
            throw TrimrPixError.assetReplaceFailed(underlyingError: error)
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
