// SPDX-License-Identifier: AGPL-3.0-only
//
//  AccessibilityAnimation.swift
//  TrimrPix for iOS
//
//  Reduce-motion-aware animation helpers. When the user has enabled
//  Reduce Motion in Settings > Accessibility > Motion, the helpers
//  return nil so animations are skipped and state changes happen
//  instantly.
//

import SwiftUI
import UIKit

@MainActor
enum AccessibilityAnimation {
    /// Default animation that respects Reduce Motion.
    /// Returns nil when Reduce Motion is enabled.
    /// Usage: `withAnimation(AccessibilityAnimation.default) { ... }`
    static var `default`: Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : .default
    }

    /// Wraps an arbitrary animation so it is skipped when Reduce Motion is enabled.
    /// Usage: `withAnimation(AccessibilityAnimation.aware(.spring(duration: 0.3))) { ... }`
    static func aware(_ animation: Animation) -> Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : animation
    }
}
