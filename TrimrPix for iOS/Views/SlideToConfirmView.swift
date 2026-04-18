//
//  SlideToConfirmView.swift
//  TrimrPix for iOS
//
//  Created by Jarl Lyng on 24/03/2026.
//

import SwiftUI
import IAMJARLDesignTokens

struct SlideToConfirmView: View {

    let onConfirmed: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var offset: CGFloat = 0
    @State private var isConfirmed = false

    private let thumbSize: CGFloat = 56
    private let trackHeight: CGFloat = 64
    private let trackPadding: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let maxOffset = geometry.size.width - thumbSize - (trackPadding * 2)
            let progress = min(offset / maxOffset, 1.0)

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Common.Background.muted(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .stroke(DesignTokens.Common.Border.subtle(scheme), lineWidth: 1)
                    )

                // Label
                Text("Slide to compress")
                    .dynamicFont(size: DesignTokens.Typography.Size.sm, weight: DesignTokens.Typography.Weight.semibold, relativeTo: .subheadline)
                    .foregroundStyle(DesignTokens.Common.Text.tertiary(scheme))
                    .frame(maxWidth: .infinity)
                    .opacity(1 - progress)

                // Thumb
                Circle()
                    .fill(DesignTokens.Common.primary(scheme))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: isConfirmed ? "checkmark" : "arrow.right")
                            .dynamicFont(size: DesignTokens.Typography.Size.base, weight: DesignTokens.Typography.Weight.bold)
                            .foregroundStyle(DesignTokens.Common.OnPrimary.text(scheme))
                    )
                    .offset(x: trackPadding + offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isConfirmed else { return }
                                offset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { _ in
                                guard !isConfirmed else { return }
                                if offset >= maxOffset * 0.85 {
                                    confirm(snapTo: maxOffset)
                                } else {
                                    // Snap back
                                    withAnimation(AccessibilityAnimation.aware(.spring(duration: 0.4, bounce: 0.3))) {
                                        offset = 0
                                    }
                                }
                            }
                    )
            }
            .frame(height: trackHeight)
            // VoiceOver: users cannot perform the drag gesture, so expose the
            // whole control as a single activatable button. Double-tap triggers
            // the same confirm flow as sliding to the end.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Compress")
            .accessibilityHint("Double tap to start compressing. This replaces original photos and cannot be undone.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                guard !isConfirmed else { return }
                confirm(snapTo: maxOffset)
            }
        }
        .frame(height: trackHeight)
    }

    private func confirm(snapTo maxOffset: CGFloat) {
        withAnimation(AccessibilityAnimation.aware(.spring(duration: 0.3))) {
            offset = maxOffset
            isConfirmed = true
        }

        // Haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Delay slightly before triggering action so the animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onConfirmed()
        }
    }
}
