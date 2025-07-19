//
//  SparkleEffect.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct SparkleEffect: View {
    @State private var sparkles: [SparkleData] = []
    @State private var animationPhase: Double = 0
    @State private var isActive: Bool = false

    private struct SparkleData: Identifiable {
        let id = UUID()
        var basePosition: CGPoint
        var baseOpacity: Double
        let size: CGFloat
        let animationOffset: CGPoint
        let opacityRange: (min: Double, max: Double)
        let phaseOffset: Double
        let speed: Double
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles) { sparkle in
                    let currentOpacity = sparkle.baseOpacity + 
                        (sparkle.opacityRange.max - sparkle.opacityRange.min) * 
                        sin(animationPhase * sparkle.speed + sparkle.phaseOffset) * 0.5
                    
                    let currentPosition = CGPoint(
                        x: sparkle.basePosition.x + sparkle.animationOffset.x * sin(animationPhase * sparkle.speed + sparkle.phaseOffset),
                        y: sparkle.basePosition.y + sparkle.animationOffset.y * cos(animationPhase * sparkle.speed + sparkle.phaseOffset * 0.7)
                    )
                    
                    Image(systemName: "sparkle")
                        .font(.system(size: sparkle.size))
                        .foregroundColor(.white)
                        .opacity(max(0, min(1, currentOpacity)))
                        .position(currentPosition)
                }
            }
            .onAppear {
                generateSparkles(in: geometry.size)
                isActive = true
            }
            .onDisappear {
                isActive = false
            }
            .onChange(of: geometry.size) { _, newSize in
                generateSparkles(in: newSize)
            }
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                        animationPhase = .pi * 2
                    }
                } else {
                    animationPhase = 0
                }
            }
        }
        .allowsHitTesting(false) // Allow touch events to pass through sparkles
    }

    private func generateSparkles(in screenSize: CGSize) {
        let safeAreas = getSafeSparkleAreas(screenSize: screenSize)
        
        sparkles = (0..<12).compactMap { index in
            guard let safeArea = safeAreas.randomElement() else { return nil }
            
            let basePosition = CGPoint(
                x: CGFloat.random(in: safeArea.minX...safeArea.maxX),
                y: CGFloat.random(in: safeArea.minY...safeArea.maxY)
            )
            
            let minOpacity = Double.random(in: 0.2...0.4)
            let maxOpacity = Double.random(in: 0.6...0.9)
            
            return SparkleData(
                basePosition: basePosition,
                baseOpacity: (minOpacity + maxOpacity) / 2,
                size: CGFloat.random(in: 10.8...21.6),
                animationOffset: CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: -15...15)
                ),
                opacityRange: (min: minOpacity, max: maxOpacity),
                phaseOffset: Double(index) * 0.5,
                speed: Double.random(in: 0.5...1.2)
            )
        }
    }
    
    private func getSafeSparkleAreas(screenSize: CGSize) -> [CGRect] {
        let padding: CGFloat = 60
        let centerBoxHeight: CGFloat = 400 // Approximate height of main content
        let centerBoxY = (screenSize.height - centerBoxHeight) / 2
        
        return [
            // Top area (above main content)
            CGRect(
                x: padding,
                y: padding,
                width: screenSize.width - (padding * 2),
                height: max(100, centerBoxY - padding)
            ),
            
            // Bottom area (below main content)
            CGRect(
                x: padding,
                y: centerBoxY + centerBoxHeight + padding,
                width: screenSize.width - (padding * 2),
                height: max(100, screenSize.height - (centerBoxY + centerBoxHeight + padding * 2))
            ),
            
            // Left edge
            CGRect(
                x: 0,
                y: padding,
                width: padding,
                height: screenSize.height - (padding * 2)
            ),
            
            // Right edge
            CGRect(
                x: screenSize.width - padding,
                y: padding,
                width: padding,
                height: screenSize.height - (padding * 2)
            )
        ].filter { $0.width > 0 && $0.height > 0 }
    }
}
