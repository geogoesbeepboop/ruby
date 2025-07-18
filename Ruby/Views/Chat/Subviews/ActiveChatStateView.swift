import SwiftUI
import FoundationModels

/// The main chat interface with scrollable message list, input panel,
/// message reactions support, and long press context menus
@available(iOS 26.0, *)
struct ActiveChatStateView: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @State private var messageText = ""
    @State private var selectedMessageId: UUID?
    @State private var showingReactionPicker = false
    @State private var showingChatHistory = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var pendingMessage: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                MaterialBackground(intensity: 0.6)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat header
                    ChatHeaderView(showingChatHistory: $showingChatHistory)
                        .zIndex(1)  // Keep header above scroll content

                    // Messages list with proper spacing
                    MessagesList(
                        selectedMessageId: $selectedMessageId,
                        showingReactionPicker: $showingReactionPicker,
                        isTextFieldFocused: isTextFieldFocused
                    )
                    .layoutPriority(1)  // Give priority to messages area
                    .clipped()  // Prevent overflow
                    // Add bottom padding when keyboard is visible to ensure last message is visible
//                    .padding(.bottom, isTextFieldFocused ? 60 : 0)
                    .animation(.easeOut(duration: 0.25), value: isTextFieldFocused)

                    // Input panel
                    InputPanel(
                        messageText: $messageText,
                        isTextFieldFocused: $isTextFieldFocused,
                        sendMessage: sendMessage
                    )
                    .zIndex(1)  // Keep input panel above scroll content
                }
                
                // Chat history sidebar overlay
                ChatHistorySidebar(isOpen: $showingChatHistory)
                    .zIndex(10)  // Keep sidebar above all other content
            }
        }
        .sheet(isPresented: $showingReactionPicker) {
            ReactionPickerSheet(messageId: selectedMessageId)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .task(id: pendingMessage) {
            guard let message = pendingMessage else { return }
            await chatCoordinator.sendMessage(message)
            pendingMessage = nil
        }
    }
    
    // MARK: - Message Handling Functions
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Set pending message to trigger AI response via coordinator
        pendingMessage = text
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview {
    ActiveChatStateView()
        .environment(ChatCoordinator())
}
