//
//  ContentView.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import SwiftUI
import PhotosUI
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
                    .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Spacer()

                if viewModel.currentStep != .selectPhotos && viewModel.currentStep != .compressing {
                    Button("Start forfra") {
                        withAnimation { viewModel.reset() }
                    }
                    .font(.system(size: DesignTokens.Typography.Size.sm))
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
                Capsule()
                    .fill(index <= viewModel.currentStep.index
                          ? DesignTokens.Common.primary(scheme)
                          : DesignTokens.Common.Border.subtle(scheme))
                    .frame(height: 3)
            }
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
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(DesignTokens.Common.primary(scheme))

            // Title
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Vaelg billeder")
                    .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("Vaelg de billeder du vil komprimere fra dit fotobibliotek")
                    .font(.system(size: DesignTokens.Typography.Size.base))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            // Selected count
            if viewModel.hasImages {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.ColorToken.State.success)
                    Text("\(viewModel.images.count) billeder valgt")
                        .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold))
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
                            .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold))
                        Text(hasSelected ? "Vaelg andre billeder" : "Vaelg fra Fotos")
                            .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold))
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
                        withAnimation { viewModel.currentStep = .configure }
                        Task { await viewModel.estimateSavings() }
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Text("Naeste")
                                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold))
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
                    settingsSection(title: "Kvalitet") {
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Picker("Kvalitet", selection: $viewModel.quality) {
                                ForEach(CompressionQuality.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(viewModel.quality.description)
                                .font(.system(size: DesignTokens.Typography.Size.sm))
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

            // Compress button
            VStack(spacing: 0) {
                Divider()
                    .overlay(DesignTokens.Common.Border.subtle(scheme))

                Button {
                    withAnimation { viewModel.currentStep = .confirm }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "arrow.right")
                        Text("Naeste")
                            .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold))
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
                Text("\(viewModel.images.count) billeder")
                    .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.semibold))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                Text(viewModel.totalOriginalSize.formattedSize)
                    .font(.system(size: DesignTokens.Typography.Size.sm))
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
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                .textCase(.uppercase)

            content()
        }
    }

    private var metadataSection: some View {
        settingsSection(title: "Metadata") {
            VStack(spacing: 0) {
                ForEach(Array(MetadataStrippingOptions.labels.enumerated()), id: \.offset) { index, option in
                    let binding = Binding<Bool>(
                        get: { viewModel.metadataOptions[keyPath: option.keyPath] },
                        set: { viewModel.metadataOptions[keyPath: option.keyPath] = $0 }
                    )

                    Toggle(isOn: binding) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Text(option.label)
                                    .font(.system(size: DesignTokens.Typography.Size.base))
                                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                                Text(option.isInverted ? "behold" : "fjern")
                                    .font(.system(size: DesignTokens.Typography.Size.xs, weight: DesignTokens.Typography.Weight.semibold))
                                    .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        (option.isInverted ? DesignTokens.ColorToken.State.success : DesignTokens.ColorToken.State.warning),
                                        in: Capsule()
                                    )
                            }
                            Text(option.description)
                                .font(.system(size: DesignTokens.Typography.Size.xs))
                                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
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

    private var estimationCard: some View {
        HStack {
            if viewModel.isEstimating {
                ProgressView()
                    .controlSize(.small)
                Text("Beregner...")
                    .font(.system(size: DesignTokens.Typography.Size.sm))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            } else {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: DesignTokens.Typography.Size.xl))
                    .foregroundStyle(DesignTokens.ColorToken.State.success)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimeret besparelse")
                        .font(.system(size: DesignTokens.Typography.Size.sm))
                        .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    Text("~\(viewModel.estimatedTotalSavingsPercentage)%")
                        .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
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

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(DesignTokens.ColorToken.State.warning)

            // Title and description
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Klar til komprimering")
                    .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("De originale billeder vil blive erstattet med komprimerede versioner. Dette kan ikke fortrydes.")
                    .font(.system(size: DesignTokens.Typography.Size.base))
                    .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
            }

            // Summary
            VStack(spacing: DesignTokens.Spacing.md) {
                summaryRow(label: "Billeder", value: "\(viewModel.images.count)")
                summaryRow(label: "Kvalitet", value: viewModel.quality.rawValue)
                summaryRow(label: "Format", value: viewModel.format.rawValue)
                summaryRow(label: "Estimeret besparelse", value: "~\(viewModel.estimatedTotalSavingsPercentage)%")
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

                Button("Annuller") {
                    withAnimation { viewModel.currentStep = .configure }
                }
                .font(.system(size: DesignTokens.Typography.Size.sm))
                .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.sm))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            Spacer()
            Text(value)
                .font(.system(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold))
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
                    .animation(.linear, value: viewModel.compressionProgress)

                VStack(spacing: 2) {
                    Text("\(Int(viewModel.compressionProgress * 100))%")
                        .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
                        .foregroundStyle(DesignTokens.Common.Text.primary(scheme))
                }
            }

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("Komprimerer...")
                    .font(.system(size: DesignTokens.Typography.Size.lg, weight: DesignTokens.Typography.Weight.semibold))
                    .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

                Text("Billede \(viewModel.currentImageIndex + 1) af \(viewModel.images.count)")
                    .font(.system(size: DesignTokens.Typography.Size.base))
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
            }

            Spacer()
        }
    }
}

// MARK: - Step 3b: Result

private struct ResultStep: View {
    @Bindable var viewModel: ImageOptimizationViewModel
    @Environment(\.colorScheme) private var scheme

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

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            // Icon — success, partial, or failure
            Image(systemName: allFailed ? "xmark.circle.fill" : (hasErrors ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"))
                .font(.system(size: 72))
                .foregroundStyle(allFailed ? DesignTokens.ColorToken.State.error : (hasErrors ? DesignTokens.ColorToken.State.warning : DesignTokens.ColorToken.State.success))

            // Title
            Text(allFailed ? "Komprimering fejlede" : (hasErrors ? "Delvist faerdig" : "Faerdig!"))
                .font(.system(size: DesignTokens.Typography.Size.xl, weight: DesignTokens.Typography.Weight.bold))
                .foregroundStyle(DesignTokens.Common.Text.primary(scheme))

            // Stats
            VStack(spacing: DesignTokens.Spacing.lg) {
                statRow(
                    label: "Komprimeret",
                    value: "\(successCount) af \(viewModel.images.count)",
                    color: successCount > 0 ? DesignTokens.Common.Text.primary(scheme) : DesignTokens.ColorToken.State.error
                )

                if hasErrors {
                    statRow(
                        label: "Fejlede",
                        value: "\(failCount)",
                        color: DesignTokens.ColorToken.State.error
                    )
                }

                if successCount > 0 {
                    statRow(label: "Plads sparet", value: totalSaved.formattedSize)
                    statRow(label: "Gns. besparelse", value: "\(averageSavings)%")
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
                                .font(.system(size: DesignTokens.Typography.Size.sm))

                            Text(item.error?.localizedDescription ?? "Ukendt fejl")
                                .font(.system(size: DesignTokens.Typography.Size.sm))
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
                withAnimation { viewModel.reset() }
            } label: {
                Text("Komprimer flere billeder")
                    .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold))
                    .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .background(DesignTokens.Common.primary(scheme), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
    }

    private func statRow(label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: DesignTokens.Typography.Size.base))
                .foregroundStyle(DesignTokens.Common.Text.secondary(scheme))
            Spacer()
            Text(value)
                .font(.system(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold))
                .foregroundStyle(color ?? DesignTokens.Common.Text.primary(scheme))
        }
    }
}

#Preview {
    ContentView()
}
