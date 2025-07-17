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
        .accessibilityLabel("Lotus AI Chatbot")
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

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    MainChatBotView()
}
