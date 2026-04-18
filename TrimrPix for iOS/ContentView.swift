//
//  ContentView.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import SwiftUI
import PhotosUI
import StoreKit
import IAMJARLDesignTokens

struct ContentView: View {

    @State private var viewModel = ImageOptimizationViewModel()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            DesignTokens.Common.Background.app(scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Step content
                switch viewModel.currentStep {
                case .selectPhotos:
                    SelectPhotosStep(viewModel: viewModel)
                case .configure:
                    ConfigureStep(viewModel: viewModel)
                case .confirm:
                    ConfirmStep(viewModel: viewModel)
                case .compressing:
                    CompressingStep(viewModel: viewModel)
                case .result:
                    ResultStep(viewModel: viewModel)
                }
            }
        }
        .onChange(of: viewModel.selectedPhotos) {
            Task { await viewModel.loadSelectedPhotos() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("TrimrPix")
                    .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Spacer()

                if viewModel.currentStep != .selectPhotos && viewModel.currentStep != .compressing {
                    Button("Start over") {
                        withAnimation(AccessibilityAnimation.default) { viewModel.reset() }
                    }
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                }
            }

            // Step indicator
            stepIndicator
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.sm)
        .padding(.bottom, DesignTokens.Spacing.md)
    }

    private var stepIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<4, id: \.self) { index in
                let isActive = index <= viewModel.currentStep.index
                Capsule()
                    .fill(isActive
                          ? DesignTokens.Common.primary(scheme)
                          : DesignTokens.Common.Border.subtle(scheme))
                    // Differentiate without color: active steps are taller
                    // so progress is visible even at grayscale or with color
                    // vision deficiencies.
                    .frame(height: isActive ? 4 : 2)
                    .opacity(isActive ? 1.0 : 0.6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(viewModel.currentStep.index + 1) of 4")
        .accessibilityValue(stepName(for: viewModel.currentStep))
    }

    private func stepName(for step: AppStep) -> String {
        switch step {
        case .selectPhotos: return "Select photos"
        case .configure: return "Configure"
        case .confirm: return "Confirm"
        case .compressing: return "Compressing"
        case .result: return "Result"
        }
    }
}

// MARK: - Step 1: Select Photos

private struct SelectPhotosStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: "photo.on.rectangle.angled")
                .dynamicFont(size: 72, weight: .thin, relativeTo: .largeTitle)
                .foregroundStyle(DesignTokens.Common.primary(scheme))

            // Title
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Select photos")
                    .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("Choose the photos you want to compress from your library")
                    .dynamicFont(size: DesignTokens.Typography.Size.base)
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            // Selected count or loading indicator
            if viewModel.isLoadingImages {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading photos...")
                        .dynamicFont(size: DesignTokens.Typography.Size.base)
                        .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(
                    DesignTokens.Common.Background.card(scheme),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
                )
            } else if viewModel.hasImages {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.ColorToken.State.success)
                    Text(viewModel.images.count == 1 ? "1 photo selected" : "\(viewModel.images.count) photos selected")
                        .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold)
                        .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                }
                .padding(.vertical, DesignTokens.Spacing.md)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .background(
                    DesignTokens.Common.Background.card(scheme),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
                )
            }

            Spacer()

            // Actions
            let hasSelected = viewModel.hasImages
            VStack(spacing: DesignTokens.Spacing.md) {
                PhotosPicker(
                    selection: $viewModel.selectedPhotos,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: hasSelected ? "arrow.triangle.2.circlepath" : "plus")
                            .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold)
                        Text(hasSelected ? "Choose different photos" : "Choose from Photos")
                            .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold)
                    }
                    .foregroundStyle(hasSelected
                                     ? DesignTokens.Common.primary(scheme)
                                     : DesignTokens.Common.OnPrimary.text(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .background(
                        hasSelected
                        ? AnyShapeStyle(DesignTokens.Common.Background.card(scheme))
                        : AnyShapeStyle(DesignTokens.Common.primary(scheme)),
                        in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    )
                    .overlay(
                        hasSelected
                        ? RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .stroke(DesignTokens.Common.Border.default(scheme), lineWidth: 1)
                        : nil
                    )
                }

                if viewModel.hasImages {
                    Button {
                        withAnimation(AccessibilityAnimation.default) { viewModel.currentStep = .configure }
                        Task { await viewModel.estimateSavings() }
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text("Next")
                                .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignTokens.Spacing.lg)
                        .background(DesignTokens.Common.primary(scheme), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }
}

// MARK: - Step 2: Configure

private struct ConfigureStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Summary card
                    summaryCard

                    // Quality selection
                    settingsSection(title: "Quality") {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Picker("Quality", selection: $viewModel.quality) {
                                ForEach(CompressionQuality.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(viewModel.quality.description)
                                .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Format selection
                    settingsSection(title: "Format") {
                        Picker("Format", selection: $viewModel.format) {
                            ForEach(OutputFormat.allCases) { fmt in
                                Text(fmt.rawValue).tag(fmt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Metadata options
                    metadataSection

                    // Estimation card
                    estimationCard
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.md)
            }

            // Next button
            VStack(spacing: 0) {
                Divider()
                    .overlay(DesignTokens.Common.Border.subtle(scheme))

                Button {
                    withAnimation(AccessibilityAnimation.default) { viewModel.currentStep = .confirm }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "arrow.right")
                        Text("Next")
                            .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold)
                    }
                    .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .background(DesignTokens.Common.primary(scheme), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
        }
        .onChange(of: viewModel.quality) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.format) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.metadataOptions.keepDateTime) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.metadataOptions.keepCameraSettings) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.metadataOptions.keepGPS) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.metadataOptions.keepIPTC) {
            Task { await viewModel.estimateSavings() }
        }
        .onChange(of: viewModel.metadataOptions.keepAppleMaker) {
            Task { await viewModel.estimateSavings() }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Thumbnail stack
            HStack(spacing: -12) {
                ForEach(viewModel.images.prefix(3)) { item in
                    if let thumb = item.thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .stroke(DesignTokens.Common.Background.app(scheme), lineWidth: 2)
                            )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.images.count == 1 ? "1 photo" : "\(viewModel.images.count) photos")
                    .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold)
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                Text(viewModel.totalOriginalSize.formattedSize)
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            DesignTokens.Common.Background.card(scheme),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
        )
    }

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text(title)
                .dynamicFont(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, relativeTo: .subheadline)
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .textCase(.uppercase)

            content()
        }
    }

    private var metadataSection: some View {
        settingsSection(title: "Metadata") {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Explanation
                Text("Choose which metadata to keep. Disabled items will be permanently removed.")
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    ForEach(Array(MetadataStrippingOptions.labels.enumerated()), id: \.offset) { index, option in
                        let binding = Binding<Bool>(
                            get: { viewModel.metadataOptions[keyPath: option.keyPath] },
                            set: { viewModel.metadataOptions[keyPath: option.keyPath] = $0 }
                        )
                        let isKept = binding.wrappedValue

                        Toggle(isOn: binding) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .dynamicFont(size: DesignTokens.Typography.Size.base)
                                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                                Text(isKept ? option.description : "Will be removed")
                                    .dynamicFont(size: DesignTokens.Typography.Size.xs, relativeTo: .caption)
                                    .foregroundStyle(isKept
                                        ? DesignTokens.Common.Text.tertiary(scheme)
                                        : DesignTokens.ColorToken.State.warning)
                            }
                        }
                        .tint(DesignTokens.Common.primary(scheme))
                        .padding(.vertical, DesignTokens.Spacing.sm)

                        if index < MetadataStrippingOptions.labels.count - 1 {
                            Divider()
                                .overlay(DesignTokens.Common.Border.subtle(scheme))
                        }
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    DesignTokens.Common.Background.card(scheme),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
                )
            }
        }
    }

    private var estimationCard: some View {
        HStack {
            if viewModel.isEstimating {
                ProgressView()
                    .controlSize(.small)
                Text("Estimating...")
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .dynamicFont(size: DesignTokens.Typography.Size.xl, relativeTo: .title2)
                    .foregroundStyle(DesignTokens.ColorToken.State.success)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimated savings")
                        .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                        .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    Text("~\(viewModel.estimatedTotalSavingsPercentage)%")
                        .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                        .foregroundStyle(DesignTokens.ColorToken.State.success)
                }

                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            DesignTokens.Common.Background.card(scheme),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
        )
    }
}

// MARK: - Step 3: Confirm

private struct ConfirmStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme

    private var metadataKeptCount: Int {
        let opts = viewModel.metadataOptions
        return [opts.keepDateTime, opts.keepCameraSettings, opts.keepGPS, opts.keepIPTC, opts.keepAppleMaker].filter(\.self).count
    }

    private var metadataStrippedCount: Int {
        5 - metadataKeptCount
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon — informational, not alarming
            Image(systemName: "info.circle.fill")
                .dynamicFont(size: 56, relativeTo: .largeTitle)
                .foregroundStyle(DesignTokens.Common.primary(scheme))

            // Title and description
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Ready to compress")
                    .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("The original photos will be replaced with compressed versions. This cannot be undone.")
                    .dynamicFont(size: DesignTokens.Typography.Size.base)
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            // Summary
            VStack(spacing: DesignTokens.Spacing.md) {
                summaryRow(label: "Photos", value: "\(viewModel.images.count)")
                summaryRow(label: "Quality", value: viewModel.quality.rawValue)
                summaryRow(label: "Format", value: viewModel.format.rawValue)
                summaryRow(label: "Metadata", value: metadataStrippedCount == 0 ? "Keep all" : "\(metadataStrippedCount) removed")
                summaryRow(label: "Est. savings", value: "~\(viewModel.estimatedTotalSavingsPercentage)%")
            }
            .padding(DesignTokens.Spacing.xl)
            .background(
                DesignTokens.Common.Background.card(scheme),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer()

            // Slide to confirm
            VStack(spacing: DesignTokens.Spacing.md) {
                SlideToConfirmView {
                    Task { await viewModel.compress() }
                }

                Button("Cancel") {
                    withAnimation(AccessibilityAnimation.default) { viewModel.currentStep = .configure }
                }
                .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .alert("Photo access required", isPresented: $viewModel.showPhotosAccessAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("TrimrPix needs full access to your photo library to compress and replace photos. Please enable access in Settings.")
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            Spacer()
            Text(value)
                .dynamicFont(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, relativeTo: .subheadline)
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
        }
    }
}

// MARK: - Step 4a: Compressing

private struct CompressingStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Circular progress
            ZStack {
                Circle()
                    .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 4)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.compressionProgress)
                    .stroke(DesignTokens.Common.primary(scheme), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(AccessibilityAnimation.aware(.linear), value: viewModel.compressionProgress)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.compressionProgress * 100))%")
                        .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                        .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                }
            }

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Compressing...")
                    .dynamicFont(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold, relativeTo: .title3)
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("Photo \(viewModel.currentImageIndex + 1) of \(viewModel.images.count)")
                    .dynamicFont(size: DesignTokens.Typography.Size.base)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }

            Spacer()

            // Cancel button
            Button {
                viewModel.cancelCompression()
            } label: {
                Text("Cancel")
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }
}

// MARK: - Step 4b: Result

private struct ResultStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.requestReview) private var requestReview

    private var successCount: Int {
        viewModel.images.filter(\.isCompressed).count
    }

    private var failCount: Int {
        viewModel.images.filter { $0.error != nil }.count
    }

    private var totalSaved: Int64 {
        viewModel.images.reduce(0) { acc, item in
            guard let compressed = item.compressedSize else { return acc }
            return acc + (item.originalSize - compressed)
        }
    }

    private var averageSavings: Int {
        let compressed = viewModel.images.filter(\.isCompressed)
        guard !compressed.isEmpty else { return 0 }
        let sum = compressed.reduce(0) { $0 + $1.savingsPercentage }
        return sum / compressed.count
    }

    private var hasErrors: Bool { failCount > 0 }
    private var allFailed: Bool { successCount == 0 }
    private var wasCancelled: Bool { viewModel.wasCancelled }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: allFailed ? "xmark.circle.fill" : (hasErrors || wasCancelled ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"))
                .dynamicFont(size: 72, relativeTo: .largeTitle)
                .foregroundStyle(allFailed ? DesignTokens.ColorToken.State.error : (hasErrors || wasCancelled ? DesignTokens.ColorToken.State.warning : DesignTokens.ColorToken.State.success))

            // Title
            Text(allFailed ? "Compression failed" : (wasCancelled ? "Cancelled" : (hasErrors ? "Partially complete" : "Done!")))
                .dynamicFont(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold, relativeTo: .title2)
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

            // Stats
            VStack(spacing: DesignTokens.Spacing.lg) {
                statRow(
                    label: "Compressed",
                    value: "\(successCount) of \(viewModel.images.count)",
                    color: successCount > 0 ? DesignTokens.Common.Text.primary(scheme) : DesignTokens.ColorToken.State.error
                )

                if hasErrors {
                    statRow(
                        label: "Failed",
                        value: "\(failCount)",
                        color: DesignTokens.ColorToken.State.error
                    )
                }

                if successCount > 0 {
                    statRow(label: "Space saved", value: totalSaved.formattedSize)
                    statRow(label: "Avg. savings", value: "\(averageSavings)%")
                }
            }
            .padding(DesignTokens.Spacing.xl)
            .background(
                DesignTokens.Common.Background.card(scheme),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
            )
            .padding(.horizontal, DesignTokens.Spacing.lg)

            // Error details
            if hasErrors {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    ForEach(viewModel.images.filter { $0.error != nil }) { item in
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(DesignTokens.ColorToken.State.error)
                                .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)

                            Text(item.error?.localizedDescription ?? "Unknown error")
                                .dynamicFont(size: DesignTokens.Typography.Size.sm, relativeTo: .subheadline)
                                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                        }
                    }
                }
                .padding(DesignTokens.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    DesignTokens.Common.Background.card(scheme),
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.ColorToken.State.error.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            Spacer()

            // Done button
            Button {
                withAnimation(AccessibilityAnimation.default) { viewModel.reset() }
            } label: {
                Text("Compress more photos")
                    .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold)
                    .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .background(DesignTokens.Common.primary(scheme), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .onAppear {
            // Ask for a review after a fully successful compression
            if successCount > 0 && !hasErrors && !wasCancelled {
                requestReview()
            }
        }
    }

    private func statRow(label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .dynamicFont(size: DesignTokens.Typography.Size.base)
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            Spacer()
            Text(value)
                .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold)
                .foregroundStyle(color ?? DesignTokens.Common.Text.primary(scheme))
        }
    }
}

#Preview {
    ContentView()
}
