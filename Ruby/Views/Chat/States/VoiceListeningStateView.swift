import SwiftUI

/// Voice interaction state with animated microphone glow effect,
/// real-time voice waveform visualization, and transcript preview
@available(iOS 26.0, *)
struct VoiceListeningStateView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var microphoneScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var pulseAnimation = false
    @State private var showTranscript = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle blur effects
                MaterialBackground(intensity: 0.7)
                    .ignoresSafeArea()
                
                // Animated background particles
                VoiceParticleField(screenSize: geometry.size)
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Voice status indicator
                    VoiceStatusView()
                    
                    // Main microphone with glow effect
                    MainMicrophoneView(
                        microphoneScale: $microphoneScale,
                        glowOpacity: $glowOpacity,
                        pulseAnimation: $pulseAnimation
                    )
                    
                    // Voice waveform visualization
                    VoiceWaveformView()
                    
                    // Transcript preview
                    TranscriptPreview(showTranscript: $showTranscript)
                    
                    Spacer()
                    
                    // Control buttons
                    VoiceControlButtons()
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            startAnimations()
            withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
                showTranscript = true
            }
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    private func startAnimations() {
        // Microphone pulsing animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            microphoneScale = 1.1
            glowOpacity = 0.8
        }
        
        // Pulse ring animation
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            pulseAnimation = true
        }
    }
    
    private func stopAnimations() {
        microphoneScale = 1.0
        glowOpacity = 0.3
        pulseAnimation = false
    }
}

// MARK: - Voice Status

@available(iOS 26.0, *)
private struct VoiceStatusView: View {
    @Environment(ChatStore.self) private var chatStore
    
    var body: some View {
        VStack(spacing: 8) {
            AnimatedGradientText("Listening...", fontSize: 24)
            
            Text("Speak now or tap to stop")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Voice recording is active. Speak now or tap to stop.")
    }
}

// MARK: - Main Microphone

@available(iOS 26.0, *)
private struct MainMicrophoneView: View {
    @Binding var microphoneScale: CGFloat
    @Binding var glowOpacity: Double
    @Binding var pulseAnimation: Bool
    
    var body: some View {
        ZStack {
            // Pulse rings
            ForEach(0..<3, id: \.self) { index in
                PulseRing(
                    delay: Double(index) * 0.3,
                    animate: pulseAnimation
                )
            }
            
            // Main microphone button
            MicrophoneButton(
                scale: microphoneScale,
                glowOpacity: glowOpacity
            )
        }
    }
}

@available(iOS 26.0, *)
private struct PulseRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.8
    let animate: Bool
    
    var body: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color(hex: "fc9afb").opacity(opacity),
                        Color(hex: "9b6cb0").opacity(opacity * 0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: 200, height: 200)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                guard animate else { return }
                withAnimation(
                    .easeOut(duration: 2.0)
                    .delay(delay)
                    .repeatForever(autoreverses: false)
                ) {
                    scale = 1.4
                    opacity = 0.0
                }
            }
    }
}

@available(iOS 26.0, *)
private struct MicrophoneButton: View {
    @Environment(ChatStore.self) private var chatStore
    let scale: CGFloat
    let glowOpacity: Double
    
    var body: some View {
        Button(action: {
            chatStore.stopVoiceRecording()
        }) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "fc9afb").opacity(glowOpacity),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                // Main button
                GlassEffectContainer(
                    cornerRadius: 50,
                    blurRadius: 15,
                    opacity: 0.5
                ) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                }
                .shadow(
                    color: Color(hex: "fc9afb").opacity(0.4),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
        }
        .scaleEffect(scale)
        .accessibilityLabel("Stop voice recording")
        .accessibilityHint("Tap to stop recording and process your voice input")
    }
}

// MARK: - Voice Waveform

@available(iOS 26.0, *)
private struct VoiceWaveformView: View {
    @Environment(ChatStore.self) private var chatStore
    
    var body: some View {
        GlassEffectContainer(
            cornerRadius: 20,
            blurRadius: 10,
            opacity: 0.3
        ) {
            VStack(spacing: 16) {
                Text("Voice Activity")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                VoiceWaveform(
                    amplitudes: chatStore.voiceWaveform,
                    isActive: chatStore.isRecording
                )
                .frame(height: 60)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .accessibilityElement()
        .accessibilityLabel("Voice activity waveform")
        .accessibilityValue(chatStore.isRecording ? "Recording active" : "Recording inactive")
    }
}

// MARK: - Transcript Preview

@available(iOS 26.0, *)
private struct TranscriptPreview: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var showTranscript: Bool
    
    var body: some View {
        if showTranscript && !chatStore.currentInput.isEmpty {
            GlassEffectContainer(
                cornerRadius: 16,
                blurRadius: 8,
                opacity: 0.4
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcript")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        // Live indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showTranscript)
                            
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Text(chatStore.currentInput)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .animation(.easeOut(duration: 0.2), value: chatStore.currentInput)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
            .accessibilityElement()
            .accessibilityLabel("Live transcript")
            .accessibilityValue(chatStore.currentInput.isEmpty ? "No speech detected" : chatStore.currentInput)
        }
    }
}

// MARK: - Control Buttons

@available(iOS 26.0, *)
private struct VoiceControlButtons: View {
    @Environment(ChatStore.self) private var chatStore
    
    var body: some View {
        HStack(spacing: 40) {
            // Cancel button
            Button(action: {
                chatStore.stopVoiceRecording()
                chatStore.currentInput = ""
                chatStore.currentState = .activeChat
            }) {
                GlassEffectContainer(
                    cornerRadius: 25,
                    blurRadius: 8,
                    opacity: 0.3
                ) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .frame(width: 50, height: 50)
                }
            }
            .accessibilityLabel("Cancel voice recording")
            
            // Send current transcript button
            if !chatStore.currentInput.isEmpty {
                Button(action: {
                    Task {
                        await chatStore.sendMessage(chatStore.currentInput)
                    }
                    chatStore.stopVoiceRecording()
                }) {
                    GlassEffectContainer(
                        cornerRadius: 25,
                        blurRadius: 8,
                        opacity: 0.3
                    ) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                    }
                }
                .accessibilityLabel("Send transcript")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: chatStore.currentInput.isEmpty)
    }
}

// MARK: - Background Particles

@available(iOS 26.0, *)
private struct VoiceParticleField: View {
    let screenSize: CGSize
    @State private var particles: [VoiceParticle] = []
    
    private struct VoiceParticle: Identifiable {
        let id = UUID()
        let position: CGPoint
        let size: CGFloat
        let opacity: Double
        let delay: Double
        let duration: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "fc9afb").opacity(particle.opacity),
                                Color(hex: "9b6cb0").opacity(particle.opacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: 4)
                    .animation(
                        .easeInOut(duration: particle.duration)
                        .delay(particle.delay)
                        .repeatForever(autoreverses: true),
                        value: particle.opacity
                    )
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<12).map { index in
            VoiceParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 50...(screenSize.width - 50)),
                    y: CGFloat.random(in: 100...(screenSize.height - 100))
                ),
                size: CGFloat.random(in: 8...24),
                opacity: Double.random(in: 0.1...0.3),
                delay: Double(index) * 0.2,
                duration: Double.random(in: 2...4)
            )
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    VoiceListeningStateView()
        .environment(ChatStore())
}
