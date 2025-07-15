import SwiftUI

/// AI processing state with ThinkingDots animation, floating particle effects,
/// and subtle background blur intensity changes
@available(iOS 26.0, *)
struct AIThinkingStateView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var blurIntensity: Double = 0.6
    @State private var particleOpacity: Double = 0.3
    @State private var thoughtBubbleScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background with changing blur intensity
                MaterialBackground(intensity: blurIntensity)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: blurIntensity)
                
                // Floating particle field
                ThinkingParticleField(
                    screenSize: geometry.size,
                    opacity: particleOpacity
                )
                
                VStack(spacing: 50) {
                    Spacer()
                    
                    // Main thinking visualization
                    ThinkingVisualization(
                        thoughtBubbleScale: $thoughtBubbleScale,
                        rotationAngle: $rotationAngle
                    )
                    
                    // Status text with gradient animation
                    ThinkingStatusText()
                    
                    // Progress indicators
                    ProcessingIndicators()
                    
                    Spacer()
                    
                    // Cancel button (if needed)
                    if chatStore.currentState == .aiThinking {
                        CancelThinkingButton()
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            startThinkingAnimations()
        }
        .onDisappear {
            stopThinkingAnimations()
        }
    }
    
    private func startThinkingAnimations() {
        // Background blur intensity animation
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            blurIntensity = 0.9
        }
        
        // Particle opacity animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            particleOpacity = 0.7
        }
        
        // Thought bubble scaling
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            thoughtBubbleScale = 1.1
        }
        
        // Rotation animation
        withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
    
    private func stopThinkingAnimations() {
        blurIntensity = 0.6
        particleOpacity = 0.3
        thoughtBubbleScale = 1.0
        rotationAngle = 0
    }
}

// MARK: - Thinking Visualization

@available(iOS 26.0, *)
private struct ThinkingVisualization: View {
    @Binding var thoughtBubbleScale: CGFloat
    @Binding var rotationAngle: Double
    
    var body: some View {
        ZStack {
            // Outer thinking ring
            ThinkingRing(
                radius: 120,
                rotationAngle: rotationAngle,
                direction: 1
            )
            
            // Middle thinking ring
            ThinkingRing(
                radius: 90,
                rotationAngle: rotationAngle,
                direction: -1
            )
            
            // Inner thought bubble
            ThoughtBubble(scale: thoughtBubbleScale)
        }
    }
}

@available(iOS 26.0, *)
private struct ThinkingRing: View {
    let radius: CGFloat
    let rotationAngle: Double
    let direction: Double
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.brandPrimary.opacity(0.4),
                        Color.brandSecondary.opacity(0.2),
                        Color.brandHighlight.opacity(0.3),
                        Color.brandPrimary.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [10, 15]
                )
            )
            .frame(width: radius, height: radius)
            .rotationEffect(.degrees(rotationAngle * direction))
    }
}

@available(iOS 26.0, *)
private struct ThoughtBubble: View {
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            // Main bubble
            GlassEffectContainer(
                cornerRadius: 40,
                blurRadius: 15,
                opacity: 0.4
            ) {
                VStack(spacing: 12) {
                    // Brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Thinking dots
                    ThinkingDots()
                }
                .frame(width: 80, height: 80)
            }
            .shadow(
                color: Color.brandPrimary.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
        }
        .scaleEffect(scale)
    }
}

// MARK: - Status Text

@available(iOS 26.0, *)
private struct ThinkingStatusText: View {
    @State private var currentMessage = 0
    @State private var textOpacity: Double = 1.0
    
    private let messages = [
        "Processing your request...",
        "Analyzing the context...",
        "Generating response...",
        "Almost ready..."
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            AnimatedGradientText(
                messages[currentMessage],
                fontSize: 20
            )
            .opacity(textOpacity)
            .animation(.easeInOut(duration: 0.5), value: textOpacity)
            
            Text("This may take a moment")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(0.7)
        }
        .onAppear {
            startMessageRotation()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI is thinking. \(messages[currentMessage])")
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 0.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentMessage = (currentMessage + 1) % messages.count
                
                withAnimation(.easeIn(duration: 0.3)) {
                    textOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Processing Indicators

@available(iOS 26.0, *)
private struct ProcessingIndicators: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var progressValue: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Processing steps
            ProcessingSteps()
            
            // Progress visualization
            ProgressVisualization(progress: progressValue)
        }
        .onAppear {
            startProgressAnimation()
        }
    }
    
    private func startProgressAnimation() {
        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: false)) {
            progressValue = 1.0
        }
    }
}

@available(iOS 26.0, *)
private struct ProcessingSteps: View {
    @State private var activeStep = 0
    
    private let steps = [
        ("Understanding", "brain"),
        ("Processing", "gearshape.2"),
        ("Generating", "wand.and.stars")
    ]
    
    var body: some View {
        HStack(spacing: 30) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(index <= activeStep ? Color.brandPrimary.opacity(0.3) : Color.clear)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: step.1)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(
                                index <= activeStep ?
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.brandSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    
                    Text(step.0)
                        .font(.caption)
                        .foregroundStyle(index <= activeStep ? .primary : .secondary)
                }
                .animation(.easeInOut(duration: 0.5), value: activeStep)
            }
        }
        .onAppear {
            startStepAnimation()
        }
    }
    
    private func startStepAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                activeStep = (activeStep + 1) % (steps.count + 1)
            }
            
            if activeStep >= steps.count {
                activeStep = 0
            }
        }
    }
}

@available(iOS 26.0, *)
private struct ProgressVisualization: View {
    let progress: Double
    
    var body: some View {
        GlassEffectContainer(
            cornerRadius: 8,
            blurRadius: 6,
            opacity: 0.3
        ) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 8)
                    
                    // Progress bar
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.brandPrimary, Color.brandSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Shimmer effect
                    if progress > 0 {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 30, height: 8)
                            .offset(x: (geometry.size.width * progress) - 15)
                    }
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .accessibilityElement()
        .accessibilityLabel("Processing progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Cancel Button

@available(iOS 26.0, *)
private struct CancelThinkingButton: View {
    @Environment(ChatStore.self) private var chatStore
    
    var body: some View {
        Button(action: {
            // Cancel the current AI processing
            if chatStore.messages.isEmpty {
                chatStore.currentState = .activeChat
            } else {
                chatStore.currentState = .activeChat
            }
        }) {
            GlassEffectContainer(
                cornerRadius: 20,
                blurRadius: 8,
                opacity: 0.3
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .accessibilityLabel("Cancel AI processing")
        .accessibilityHint("Tap to stop the current AI processing and return to chat")
    }
}

// MARK: - Particle Field

@available(iOS 26.0, *)
private struct ThinkingParticleField: View {
    let screenSize: CGSize
    let opacity: Double
    @State private var particles: [ThinkingParticle] = []
    
    private struct ThinkingParticle: Identifiable {
        let id = UUID()
        let startPosition: CGPoint
        let endPosition: CGPoint
        let size: CGFloat
        let duration: Double
        let delay: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brandPrimary.opacity(opacity),
                                Color.brandSecondary.opacity(opacity * 0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size / 2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.startPosition)
                    .animation(
                        .easeInOut(duration: particle.duration)
                        .delay(particle.delay)
                        .repeatForever(autoreverses: true),
                        value: opacity
                    )
                    .blur(radius: 2)
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<15).map { index in
            let startX = CGFloat.random(in: 50...(screenSize.width - 50))
            let startY = CGFloat.random(in: 100...(screenSize.height - 100))
            
            return ThinkingParticle(
                startPosition: CGPoint(x: startX, y: startY),
                endPosition: CGPoint(
                    x: startX + CGFloat.random(in: -100...100),
                    y: startY + CGFloat.random(in: -100...100)
                ),
                size: CGFloat.random(in: 6...20),
                duration: Double.random(in: 3...6),
                delay: Double(index) * 0.2
            )
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    AIThinkingStateView()
        .environment(ChatStore())
}
