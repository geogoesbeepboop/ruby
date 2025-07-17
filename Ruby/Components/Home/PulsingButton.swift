//
//  PulsingButton.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct PulsingButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let isActive: Bool

    @State private var isPulsing = false

    init(
        isActive: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .onAppear {
            if isActive {
                isPulsing = true
            }
        }
        .onChange(of: isActive) { newValue in
            isPulsing = newValue
        }
    }
}
