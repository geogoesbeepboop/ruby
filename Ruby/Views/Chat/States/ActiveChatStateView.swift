import SwiftUI

/// The main chat interface with scrollable message list, input panel,
/// message reactions support, and long press context menus
@available(iOS 26.0, *)
struct ActiveChatStateView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var messageText = ""
    @State private var selectedMessageId: UUID?
    @State private var showingReactionPicker = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                MaterialBackground(intensity: 0.6)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat header
                    ChatHeaderView()
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
                        isTextFieldFocused: $isTextFieldFocused
                    )
                    .zIndex(1)  // Keep input panel above scroll content
                }
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
    }
}

extension Color {
    static func mix(_ color1: Color, _ color2: Color, ratio: CGFloat) -> Color {
        let r = Double(ratio)
        return Color(
            red: (1 - r) * color1.components.red + r * color2.components.red,
            green: (1 - r) * color1.components.green + r * color2.components.green,
            blue: (1 - r) * color1.components.blue + r * color2.components.blue
        )
    }
    
    // Legacy Ruby colors moved to LotusColors.swift theme file

    // Helper to extract RGBA components
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        #if os(iOS)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #else
        return (0, 0, 0, 1) // Add macOS support if needed
        #endif
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview {
    ActiveChatStateView()
        .environment(ChatStore())
}
