//
//  SparkleEffect.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

struct SparkleEffect: View {
    @State private var sparkles: [SparkleData] = []
    @State private var animationTimer: Timer?

    private struct SparkleData: Identifiable {
        let id = UUID()
        var position: CGPoint
        var targetPosition: CGPoint
        let size: CGFloat
        var opacity: Double
        var targetOpacity: Double
        let duration: Double
        let delay: Double
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Image(systemName: "sparkle")
                        .font(.system(size: sparkle.size))
                        .foregroundColor(.white)
                        .opacity(sparkle.opacity)
                        .position(sparkle.position)
                        .animation(
                            .easeInOut(duration: sparkle.duration)
                                .delay(sparkle.delay)
                                .repeatForever(autoreverses: false),
                            value: sparkle.opacity
                        )
                        .animation(
                            .easeInOut(duration: sparkle.duration)
                                .delay(sparkle.delay),
                            value: sparkle.position
                        )
                }
            }
            .onAppear {
                generateSparkles(in: geometry.size)
                startContinuousAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
            .onChange(of: geometry.size) { _, newSize in
                generateSparkles(in: newSize)
            }
        }
        .allowsHitTesting(false) // Allow touch events to pass through sparkles
    }

    private func generateSparkles(in screenSize: CGSize) {
        let safeAreas = getSafeSparkleAreas(screenSize: screenSize)
        
        sparkles = (0..<12).compactMap { index in
            guard let safeArea = safeAreas.randomElement() else { return nil }
            
            let position = CGPoint(
                x: CGFloat.random(in: safeArea.minX...safeArea.maxX),
                y: CGFloat.random(in: safeArea.minY...safeArea.maxY)
            )
            
            let targetPosition = CGPoint(
                x: CGFloat.random(in: safeArea.minX...safeArea.maxX),
                y: CGFloat.random(in: safeArea.minY...safeArea.maxY)
            )
            
            return SparkleData(
                position: position,
                targetPosition: targetPosition,
                size: CGFloat.random(in: 10.8...21.6), // Increased by 35%
                opacity: 0.0,
                targetOpacity: Double.random(in: 0.4...0.9),
                duration: Double.random(in: 2.0...4.0),
                delay: Double(index) * 0.2
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
    
    private func startContinuousAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            animateSparkles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func animateSparkles() {
        for index in sparkles.indices {
            withAnimation(.easeInOut(duration: sparkles[index].duration)) {
                // Animate opacity
                if sparkles[index].opacity < sparkles[index].targetOpacity {
                    sparkles[index].opacity = min(
                        sparkles[index].opacity + 0.05,
                        sparkles[index].targetOpacity
                    )
                } else {
                    sparkles[index].opacity = max(
                        sparkles[index].opacity - 0.02,
                        0.0
                    )
                    
                    // When opacity reaches 0, regenerate the sparkle
                    if sparkles[index].opacity <= 0.1 {
                        regenerateSparkle(at: index)
                    }
                }
                
                // Animate position
                let dx = sparkles[index].targetPosition.x - sparkles[index].position.x
                let dy = sparkles[index].targetPosition.y - sparkles[index].position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance > 5 {
                    let speed: CGFloat = 1.0
                    sparkles[index].position.x += (dx / distance) * speed
                    sparkles[index].position.y += (dy / distance) * speed
                } else {
                    // Reached target, set new target
                    setNewTarget(for: index)
                }
            }
        }
    }
    
    private func regenerateSparkle(at index: Int) {
        guard let geometry = sparkles.first else { return }
        
        // Get screen size (approximate)
        let screenSize = CGSize(width: 400, height: 800) // Will be updated by geometry reader
        let safeAreas = getSafeSparkleAreas(screenSize: screenSize)
        
        guard let safeArea = safeAreas.randomElement() else { return }
        
        let newPosition = CGPoint(
            x: CGFloat.random(in: safeArea.minX...safeArea.maxX),
            y: CGFloat.random(in: safeArea.minY...safeArea.maxY)
        )
        
        sparkles[index].position = newPosition
        sparkles[index].targetOpacity = Double.random(in: 0.4...0.9)
        sparkles[index].opacity = 0.0
        setNewTarget(for: index)
    }
    
    private func setNewTarget(for index: Int) {
        // Get screen size (approximate)
        let screenSize = CGSize(width: 400, height: 800) // Will be updated by geometry reader
        let safeAreas = getSafeSparkleAreas(screenSize: screenSize)
        
        guard let safeArea = safeAreas.randomElement() else { return }
        
        sparkles[index].targetPosition = CGPoint(
            x: CGFloat.random(in: safeArea.minX...safeArea.maxX),
            y: CGFloat.random(in: safeArea.minY...safeArea.maxY)
        )
    }
}
