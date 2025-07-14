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
                        showingReactionPicker: $showingReactionPicker
                    )
                    .layoutPriority(1)  // Give priority to messages area
                    .clipped()  // Prevent overflow

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
    }
}

// MARK: - Chat Header

@available(iOS 26.0, *)
private struct ChatHeaderView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var showingSettings = false
    @State private var showingChatHistory = false

    var body: some View {
        ZStack {
            // 1. Center Title and Subtitle
            VStack(spacing: 2) {
                Text("Lotus")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(chatStore.settings.selectedPersona.rawValue)
                    .font(.caption)
                    .foregroundStyle(.black)
            }

            // 2. Align Buttons to the Sides
            HStack {
                // Chat History Menu on the left (replacing AI Status Indicator)
                Button(action: { showingChatHistory = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Open chat history")

                Spacer()

                // Save session button
                if chatStore.currentSession != nil || !chatStore.messages.filter({ $0.isUser }).isEmpty {
                    Button(action: { 
                        chatStore.saveAndEndSession()
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "fc9afb"))
                    }
                    .accessibilityLabel("Save and end session")
                }

                // Settings button on the right
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Open settings")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 5) // Adjust for status bar
        .padding(.bottom, 10)
        .background(
            // Transparent Blue Overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.mix(.teal, .white, ratio: 0.4), Color.mix(.teal, .white, ratio: 0.3),
                    Color.mix(.teal, .white, ratio: 0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial) // Frosted glass effect
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showingChatHistory) {
            ChatHistorySheet()
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
