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

    private struct SparkleData: Identifiable {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let opacity: Double
        let delay: Double
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(.white)
                    .opacity(sparkle.opacity)
                    .position(sparkle.position)
                    .animation(
                        .easeInOut(duration: 2)
                            .delay(sparkle.delay)
                            .repeatForever(autoreverses: true),
                        value: sparkle.opacity
                    )
            }
        }
        .onAppear {
            generateSparkles()
        }
    }

    private func generateSparkles() {
        sparkles = (0..<8).map { index in
            SparkleData(
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                ),
                size: CGFloat.random(in: 8...16),
                opacity: Double.random(in: 0.3...0.8),
                delay: Double(index) * 0.3
            )
        }
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
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }

            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}
