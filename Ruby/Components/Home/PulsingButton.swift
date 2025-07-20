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

    @State private var animationPhase: Double = 0
    @State private var isAnimating = false

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
                .scaleEffect(isActive && isAnimating ? 1.0 + 0.1 * sin(animationPhase) : 1.0)
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
    
    private func stopAnimation() {
        isAnimating = false
        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0
        }
    }
}
