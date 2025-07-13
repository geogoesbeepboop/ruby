import SwiftUI

/// The main container view that manages state transitions and integrates all chat states
/// Features MaterialBackground with animated gradients, state management, navigation,
/// settings integration, and proper iOS 26+ compatibility
@available(iOS 26.0, *)
struct MainChatBotView: View {
    @State private var chatStore = ChatStore()
    @State private var showingSettings = false
    @State private var lastKnownState: ChatState = .activeChat
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Base animated background
            MaterialBackground()
                .ignoresSafeArea()
            
            // Main content with state transitions
            GeometryReader { geometry in
                ZStack {
                    // Only use ActiveChatStateView for all states
                    ActiveChatStateView()
                        .transition(.opacity)
                    // Lets hide this button for now
//                    if shouldShowSettingsButton {
//                        VStack {
//                            HStack {
//                                Spacer()
//                                FloatingSettingsButton(action: { showingSettings = true })
//                            }
//                            Spacer()
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 60)
//                    }
                    
                    // Error overlay
                    if let error = chatStore.lastError {
                        ErrorOverlay(error: error) {
                            chatStore.lastError = nil
                        }
                    }
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: chatStore.currentState)
            }
        }
        .environment(chatStore)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await chatStore.initializeAI()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            handleAppTermination()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Ruby AI Chatbot")
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowSettingsButton: Bool {
        switch chatStore.currentState {
        case .activeChat:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Resume any paused operations
            if chatStore.currentState == .voiceListening && !chatStore.isRecording {
                // Resume voice recording if it was interrupted
                chatStore.startVoiceRecording()
            }
        case .inactive:
            // Pause non-critical operations
            break
        case .background:
            // Stop voice recording and save state
            if chatStore.currentState == .voiceListening {
                chatStore.stopVoiceRecording()
            }
            lastKnownState = chatStore.currentState
        @unknown default:
            break
        }
    }
    
    private func handleAppTermination() {
        // Clean up resources
        if chatStore.currentState == .voiceListening {
            chatStore.stopVoiceRecording()
        }
    }
}

// MARK: - Floating Settings Button

@available(iOS 26.0, *)
private struct FloatingSettingsButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            GlassEffectContainer(
                cornerRadius: 25,
                blurRadius: 10,
                opacity: 0.4
            ) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
            }
            .shadow(
                color: .black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onPressGesture { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
        .accessibilityLabel("Open settings")
        .accessibilityHint("Tap to open app settings and preferences")
    }
}

// MARK: - Error State View

@available(iOS 26.0, *)
private struct ErrorStateView: View {
    @Environment(ChatStore.self) private var chatStore
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Error message
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(errorMessage)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Retry button
                Button(action: {
                    Task {
                        await chatStore.initializeAI()
                    }
                }) {
                    GlassEffectContainer(
                        cornerRadius: 25,
                        blurRadius: 10,
                        opacity: 0.4
                    ) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(maxWidth: 200, minHeight: 50)
                    }
                }
                
                // Return to chat button
                if !chatStore.messages.isEmpty {
                    Button(action: {
                        chatStore.currentState = .activeChat
                    }) {
                        Text("Return to Chat")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error occurred: \(errorMessage). Try again or return to chat options available.")
    }
}

// MARK: - Error Overlay

@available(iOS 26.0, *)
private struct ErrorOverlay: View {
    let error: ChatError
    let dismissAction: () -> Void
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            
            GlassEffectContainer(
                cornerRadius: 16,
                blurRadius: 12,
                opacity: 0.5
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Error")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text(error.localizedDescription)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: dismissAction) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismissAction()
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Error notification: \(error.localizedDescription)")
        .accessibilityHint("Will dismiss automatically or tap X to close")
    }
}

// MARK: - Settings View

@available(iOS 26.0, *)
private struct SettingsView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                MaterialBackground(intensity: 0.5)
                    .ignoresSafeArea()
                
                List {
                    // AI Persona Section
                    Section("AI Personality") {
                        ForEach(AIPersona.allCases, id: \.self) { persona in
                            PersonaRow(
                                persona: persona,
                                isSelected: chatStore.settings.selectedPersona == persona
                            ) {
                                chatStore.updatePersona(persona)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // Preferences Section
                    Section("Preferences") {
                        SettingsToggle(
                            title: "Voice Input",
                            subtitle: "Enable voice recording",
                            isOn: .constant(chatStore.settings.voiceEnabled)
                        )
                        
                        SettingsToggle(
                            title: "Streaming Responses",
                            subtitle: "See AI responses as they're generated",
                            isOn: .constant(chatStore.settings.streamingEnabled)
                        )
                        
                        SettingsToggle(
                            title: "Auto-save Conversations",
                            subtitle: "Automatically save chat history",
                            isOn: .constant(chatStore.settings.autoSaveConversations)
                        )
                    }
                    .listRowBackground(Color.clear)
                    
                    // Actions Section
                    Section("Actions") {
                        Button(action: {
                            chatStore.startNewSession()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color(hex: "fc9afb"))
                                Text("New Conversation")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            // Export conversation functionality
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                                Text("Export Chat")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "fc9afb"))
                }
            }
        }
    }
}

@available(iOS 26.0, *)
private struct PersonaRow: View {
    let persona: AIPersona
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.rawValue)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(persona.systemPrompt)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "fc9afb"))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 26.0, *)
private struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "fc9afb")))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions

extension View {
    func onPressGesture(perform action: @escaping (Bool) -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in action(true) }
                .onEnded { _ in action(false) }
        )
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    MainChatBotView()
}
