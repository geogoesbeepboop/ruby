//
//  ThinkingDots.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct ThinkingDots: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.brandSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(
                        animationPhase == index ? 1.3 : 0.8
                    )
                    .opacity(
                        animationPhase == index ? 1.0 : 0.6
                    )
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
        }
    }
}
