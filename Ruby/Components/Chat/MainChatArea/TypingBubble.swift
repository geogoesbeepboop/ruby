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
        HStack {
            // Compact thinking bubble without ChatBubble wrapper
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.brandSecondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(
                            animationPhase == index ? 1.2 : 0.8
                        )
                        .opacity(
                            animationPhase == index ? 1.0 : 0.6
                        )
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                // Compact AI bubble background
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.2),
                        Color.primary.opacity(0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: 80) // Keep it compact
            
            Spacer()
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

@available(iOS 26.0, *)
#Preview {
    TypingBubbleView()
        .environment(ChatCoordinator())
}
