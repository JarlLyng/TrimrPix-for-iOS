// SPDX-License-Identifier: AGPL-3.0-only
//
//  SegmentedSelector.swift
//  TrimrPix for iOS
//

import SwiftUI
import IAMJARLDesignTokens

/// A segmented picker that respects Dynamic Type.
///
/// SwiftUI's `.pickerStyle(.segmented)` is backed by `UISegmentedControl`, which
/// does not scale its labels with Dynamic Type. At accessibility text sizes that
/// leaves the controls as the smallest text on the screen: the user can read
/// every word explaining a setting and not the setting itself (#17).
///
/// This behaves the same way at normal sizes, in a row of equal-width segments,
/// and switches to a full-width vertical list once the text reaches an
/// accessibility size, where a row could not fit legibly however it was laid out.
///
/// Selection is shown with a filled segment rather than a lighter one, so it does
/// not rely on colour alone and reads the same with Differentiate Without Color.
struct SegmentedSelector<Option: Hashable & Identifiable>: View {
    /// Describes the group to VoiceOver, e.g. "Target size".
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let trackPadding: CGFloat = 4

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: trackPadding) {
                    ForEach(options) { segment($0) }
                }
            } else {
                HStack(spacing: trackPadding) {
                    ForEach(options) { segment($0) }
                }
            }
        }
        .padding(trackPadding)
        .background(
            DesignTokens.Common.Background.muted(scheme),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func segment(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            withAnimation(AccessibilityAnimation.aware(.easeOut(duration: 0.15))) {
                selection = option
            }
        } label: {
            Text(label(option))
                .dynamicFont(
                    size: DesignTokens.Typography.Size.sm,
                    weight: isSelected ? DesignTokens.Typography.Weight.semibold : DesignTokens.Typography.Weight.regular,
                    relativeTo: .subheadline
                )
                .foregroundStyle(isSelected
                                 ? DesignTokens.Common.OnPrimary.text(scheme)
                                 : DesignTokens.Common.Text.secondary(scheme))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .background(
                    isSelected ? DesignTokens.Common.primary(scheme) : Color.clear,
                    in: RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
