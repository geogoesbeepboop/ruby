//
//  FloatingOrb.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct FloatingOrb: View {
    let size: CGFloat
    let color: Color
    let offset: CGSize
    let delay: Double
    @State private var animate = false

    init(
        size: CGFloat = CGFloat.random(in: 20...80),
        color: Color = Color.brandPrimary.opacity(0.4),
        offset: CGSize,
        delay: Double
    ) {
        self.size = size
        self.color = color
        self.offset = offset
        self.delay = delay
    }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.1)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 8)
            .offset(
                x: animate ? offset.width + 50 : offset.width - 50,
                y: animate ? offset.height + 30 : offset.height - 30
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3...8))
                        .delay(delay)
                        .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
    }
}
