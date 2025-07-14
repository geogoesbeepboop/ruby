//
//  TypingBubble.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct TypingBubbleView: View {
    @State private var animationPhase = 0

    var body: some View {
        ChatBubble(isUser: false, timestamp: Date()) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(hex: "9b6cb0"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            animationPhase == index ? 1.4 : 0.8
                        )
                        .opacity(
                            animationPhase == index ? 1.0 : 0.6
                        )
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: animationPhase
                        )
                }

                // Add some spacing to make it look more like a message
                Spacer().frame(width: 20)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .id("typing")
        .onAppear {
            startTypingAnimation()
        }
        .accessibilityLabel("AI is typing")
    }

    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}
