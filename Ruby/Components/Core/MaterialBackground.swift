//
//  MaterialBackground.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct MaterialBackground: View {
    let colors: [Color]
    let intensity: Double

    init(
        colors: [Color] = [
        Color.brandPrimary
        ],
        intensity: Double = 1.0
    ) {
        self.colors = colors
        self.intensity = intensity
    }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colors.map { $0.opacity(intensity) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated overlay gradient
//            RadialGradient(
//                colors: [
//                    colors[1].opacity(0.3 * intensity),
//                    Color.clear,
//                ],
//                center: .center,
//                startRadius: 100,
//                endRadius: 400
//            )
            .scaleEffect(1.5)
            .animation(
                .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                value: intensity
            )
        }
    }
}
