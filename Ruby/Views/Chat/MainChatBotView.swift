import SwiftUI

/// The main container view that manages state transitions and integrates all chat states
/// Features MaterialBackground with animated gradients, state management, navigation,
/// settings integration, and proper iOS 26+ compatibility
@available(iOS 26.0, *)
struct MainChatBotView: View {
    @State private var chatCoordinator = ChatCoordinator()
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
                    ActiveChatStateView()
                        .transition(.opacity)                    
                    // Error overlay
                    if let error = chatCoordinator.uiManager.lastError {
                        ErrorOverlay(error: error) {
                            chatCoordinator.uiManager.clearError()
                        }
                    }
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: chatCoordinator.uiManager.currentState)
            }
        }
        .environment(chatCoordinator)
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
        switch chatCoordinator.uiManager.currentState {
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
            if chatCoordinator.uiManager.currentState == .voiceListening && !chatCoordinator.voiceManager.isRecording {
                // Resume voice recording if it was interrupted
                Task {
                    await chatCoordinator.startVoiceRecording()
                }
            }
        case .inactive:
            // Pause non-critical operations
            break
        case .background:
            // Stop voice recording and save state
            if chatCoordinator.uiManager.currentState == .voiceListening {
                Task {
                    await chatCoordinator.stopVoiceRecording()
                }
            }
            lastKnownState = chatCoordinator.uiManager.currentState
        @unknown default:
            break
        }
    }
    
    private func handleAppTermination() {
        // Clean up resources
        if chatCoordinator.uiManager.currentState == .voiceListening {
            Task {
                await chatCoordinator.stopVoiceRecording()
            }
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    MainChatBotView()
}
