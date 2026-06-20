// SPDX-License-Identifier: AGPL-3.0-only
//
//  DynamicFont.swift
//  TrimrPix for iOS
//
//  Bridges DesignTokens.Typography.Size (fixed CGFloat values) to SwiftUI's
//  Dynamic Type system. Uses @ScaledMetric so fonts scale with the user's
//  preferred text size (Settings > Accessibility > Display & Text Size).
//

import SwiftUI

extension View {
    /// Apply a font that scales with Dynamic Type while preserving the exact
    /// visual size from the design token system at the default text size.
    ///
    /// - Parameters:
    ///   - size: Base size in points (typically from `DesignTokens.Typography.Size`).
    ///   - weight: Font weight.
    ///   - relativeTo: The text style to scale relative to. Defaults to `.body`.
    ///     Choose a style that semantically matches the content (e.g. `.title2` for
    ///     large headings, `.caption` for small labels) so scaling feels proportional.
    func dynamicFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        modifier(DynamicFontModifier(size: size, weight: weight, style: style))
    }
}

private struct DynamicFontModifier: ViewModifier {
    @ScaledMetric private var scaledSize: CGFloat
    let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, style: Font.TextStyle) {
        self._scaledSize = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight))
    }
}
