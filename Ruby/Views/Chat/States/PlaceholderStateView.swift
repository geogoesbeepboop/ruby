import SwiftUI

/// The initial state when no conversation exists
/// Features full-screen glassmorphic background with floating orbs,
/// centered prompt, animated sparkle effects, and pulsing microphone button
@available(iOS 26.0, *)
struct PlaceholderStateView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var showTextInput = false
    @State private var textFieldText = ""
    @State private var isAnimating = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with animated gradients
                MaterialBackground(intensity: 0.8)
                    .ignoresSafeArea()
                
                // Floating orbs for ambiance
                FloatingOrbsLayer(screenSize: geometry.size)
                
                // Sparkle effects
                SparkleEffect()
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Welcome message
                    WelcomeMessageView()
                    
                    Spacer()
                    
                    // Input controls
                    InputControlsView(
                        showTextInput: $showTextInput,
                        textFieldText: $textFieldText,
                        isTextFieldFocused: $isTextFieldFocused
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showTextInput)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Supporting Views

@available(iOS 26.0, *)
private struct FloatingOrbsLayer: View {
    let screenSize: CGSize
    
    var body: some View {
        ZStack {
            // Multiple floating orbs at different positions
            ForEach(0..<6, id: \.self) { index in
                FloatingOrb(
                    size: CGFloat.random(in: 40...120),
                    color: orbColor(for: index),
                    offset: orbOffset(for: index),
                    delay: Double(index) * 0.8
                )
            }
        }
    }
    
    private func orbColor(for index: Int) -> Color {
        let colors = [
            Color(hex: "fc9afb").opacity(0.4),
            Color(hex: "9b6cb0").opacity(0.3),
            Color(hex: "f7e6ff").opacity(0.5)
        ]
        return colors[index % colors.count]
    }
    
    private func orbOffset(for index: Int) -> CGSize {
        let positions = [
            CGSize(width: -screenSize.width * 0.3, height: -screenSize.height * 0.2),
            CGSize(width: screenSize.width * 0.4, height: -screenSize.height * 0.3),
            CGSize(width: -screenSize.width * 0.2, height: screenSize.height * 0.1),
            CGSize(width: screenSize.width * 0.3, height: screenSize.height * 0.2),
            CGSize(width: 0, height: -screenSize.height * 0.4),
            CGSize(width: screenSize.width * 0.1, height: screenSize.height * 0.3)
        ]
        return positions[index % positions.count]
    }
}

@available(iOS 26.0, *)
private struct WelcomeMessageView: View {
    @State private var messageOpacity: Double = 0
    @State private var messageScale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            // Main welcome text
            AnimatedGradientText(
                "What should we talk about today?",
                fontSize: 28
            )
            .multilineTextAlignment(.center)
            .opacity(messageOpacity)
            .scaleEffect(messageScale)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                    messageOpacity = 1.0
                    messageScale = 1.0
                }
            }
            
            // Subtitle
            Text("Start a conversation or use your voice")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .opacity(messageOpacity * 0.8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to chat. What should we talk about today? Start a conversation or use your voice.")
    }
}

@available(iOS 26.0, *)
private struct InputControlsView: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var showTextInput: Bool
    @Binding var textFieldText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Text input field (conditionally shown)
            if showTextInput {
                TextInputField(
                    text: $textFieldText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: handleTextSend
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
            
            // Control buttons
            HStack(spacing: 24) {
                // Text input toggle button
                if !showTextInput {
                    TextInputButton(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showTextInput = true
                        }
                        isTextFieldFocused = true
                    })
                }
                
                // Voice input button
                VoiceInputButton()
            }
        }
    }
    
    private func handleTextSend() {
        guard !textFieldText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await chatStore.sendMessage(textFieldText)
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            showTextInput = false
            textFieldText = ""
        }
    }
}

@available(iOS 26.0, *)
private struct TextInputField: View {
    @Binding var text: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        GlassEffectContainer(
            cornerRadius: 24,
            blurRadius: 12,
            opacity: 0.4
        ) {
            HStack(spacing: 12) {
                TextField("Type your message...", text: $text, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .lineLimit(1...4)
                    .submitLabel(.send)
                    .onSubmit(onSend)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Message input field with send button")
    }
}

@available(iOS 26.0, *)
private struct TextInputButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GlassEffectContainer(
                cornerRadius: 30,
                blurRadius: 10,
                opacity: 0.3
            ) {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                    .padding(18)
            }
        }
        .accessibilityLabel("Open text input")
        .accessibilityHint("Tap to type your message")
    }
}

@available(iOS 26.0, *)
private struct VoiceInputButton: View {
    @Environment(ChatStore.self) private var chatStore
    
    var body: some View {
        PulsingButton(
            isActive: true,
            action: {
                chatStore.startVoiceRecording()
            }
        ) {
            GlassEffectContainer(
                cornerRadius: 35,
                blurRadius: 12,
                opacity: 0.4
            ) {
                Image(systemName: "mic.fill")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .padding(22)
            }
            .shadow(
                color: Color(hex: "fc9afb").opacity(0.3),
                radius: 15,
                x: 0,
                y: 5
            )
        }
        .accessibilityLabel("Start voice recording")
        .accessibilityHint("Tap and speak to send a voice message")
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    PlaceholderStateView()
        .environment(ChatStore())
}