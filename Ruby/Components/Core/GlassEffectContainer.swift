//
//  GlassEffectContainer.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct GlassEffectContainer<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let material: Material

    init(
        cornerRadius: CGFloat = 20,
        blurRadius: CGFloat = 10,
        opacity: Double = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        // Use appropriate material based on opacity for better glass effect
        if opacity > 0.5 {
            self.material = .thin
        } else if opacity > 0.3 {
            self.material = .ultraThin
        } else {
            self.material = .ultraThinMaterial
        }
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(material)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.8),
                                        .white.opacity(0.2),
                                        .clear,
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                    .shadow(
                        color: .black.opacity(0.04),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
            )
    }
}
