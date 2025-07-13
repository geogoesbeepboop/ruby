import SwiftUI

// MARK: - Glassmorphic Design System

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

struct MaterialBackground: View {
    let colors: [Color]
    let intensity: Double

    init(
        colors: [Color] = [
            Color(hex: "f7e6ff"), Color(hex: "fdb5fd"), Color(hex: "b794c7"),
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
            RadialGradient(
                colors: [
                    colors[1].opacity(0.3 * intensity),
                    Color.clear,
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .scaleEffect(1.5)
            .animation(
                .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                value: intensity
            )
        }
    }
}

struct FloatingOrb: View {
    let size: CGFloat
    let color: Color
    let offset: CGSize
    let delay: Double
    @State private var animate = false

    init(
        size: CGFloat = CGFloat.random(in: 20...80),
        color: Color = Color(hex: "fc9afb").opacity(0.4),
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

struct AnimatedGradientText: View {
    let text: String
    let fontSize: CGFloat
    @State private var animationOffset: CGFloat = 0

    init(_ text: String, fontSize: CGFloat = 24) {
        self.text = text
        self.fontSize = fontSize
    }

    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: "fc9afb"),
                Color(hex: "9b6cb0"),
                Color(hex: "fc9afb"),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .offset(x: animationOffset)
        .mask(
            Text(text)
                .font(
                    .system(size: fontSize, weight: .medium, design: .rounded)
                )
        )
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                    .repeatForever(autoreverses: false)
            ) {
                animationOffset = 200
            }
        }
    }
}

struct VoiceWaveform: View {
    let amplitudes: [Float]
    let isActive: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<amplitudes.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "fc9afb"),
                                Color(hex: "9b6cb0"),
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        width: 4,
                        height: max(
                            4,
                            CGFloat(amplitudes[index]) * 60 + (isActive ? 8 : 4)
                        )
                    )
                    .animation(
                        .easeInOut(duration: 0.1),
                        value: amplitudes[index]
                    )
            }
        }
    }
}

struct ThinkingDots: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "9b6cb0"))
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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (
                int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 255, 255, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Layout Components

struct ChatBubble<Content: View>: View {
    let content: Content
    let isUser: Bool
    let timestamp: Date

    init(isUser: Bool, timestamp: Date, @ViewBuilder content: () -> Content) {
        self.isUser = isUser
        self.timestamp = timestamp
        self.content = content()
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                GlassEffectContainer(
                    cornerRadius: 18,
                    blurRadius: 8,
                    opacity: isUser ? 0.4 : 0.2
                ) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background {
                    if isUser {
                        LinearGradient(
                            colors: [
                                Color(hex: "fc9afb").opacity(0.3),
                                Color(hex: "9b6cb0").opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }

                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
            }

            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}
