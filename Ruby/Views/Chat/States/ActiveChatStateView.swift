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
                        .zIndex(1) // Keep header above scroll content

                    // Messages list with proper spacing
                    MessagesList(
                        selectedMessageId: $selectedMessageId,
                        showingReactionPicker: $showingReactionPicker
                    )
                    .layoutPriority(1) // Give priority to messages area
                    .clipped() // Prevent overflow

                    // Input panel
                    InputPanel(
                        messageText: $messageText,
                        isTextFieldFocused: $isTextFieldFocused
                    )
                    .zIndex(1) // Keep input panel above scroll content
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

    var body: some View {
        GlassEffectContainer(
            cornerRadius: 0,
            blurRadius: 8,
            opacity: 0.3
        ) {
            HStack {
                // AI status indicator
                AIStatusIndicator()

                Spacer()

                // Chat title
                VStack(spacing: 2) {
                    Text("Ruby")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
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
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Settings button
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Open settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }
}

@available(iOS 26.0, *)
private struct AIStatusIndicator: View {
    @Environment(ChatStore.self) private var chatStore

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .animation(
                    .easeInOut(duration: 0.5),
                    value: chatStore.currentState
                )

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch chatStore.currentState {
        case .activeChat:
            return .green
        case .aiThinking, .streaming:
            return Color(hex: "fc9afb")
        case .voiceListening:
            return .blue
        case .error:
            return .red
        default:
            return .gray
        }
    }

    private var statusText: String {
        switch chatStore.currentState {
        case .activeChat:
            return "Online"
        case .aiThinking:
            return "Thinking..."
        case .streaming:
            return "Typing..."
        case .voiceListening:
            return "Listening"
        case .error:
            return "Error"
        default:
            return "Ready"
        }
    }
}

// MARK: - Messages List

@available(iOS 26.0, *)
private struct MessagesList: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var selectedMessageId: UUID?
    @Binding var showingReactionPicker: Bool

    @State private var scrollProxy: ScrollViewProxy?
    @State private var shouldMaintainPosition = false
    @State private var lastScrollTargetId: AnyHashable?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatStore.messages) { message in
                        MessageBubbleView(
                            message: message,
                            onLongPress: { messageId in
                                selectedMessageId = messageId
                                showingReactionPicker = true
                            }
                        )
                        .id(message.id)
                    }

                    // AI typing bubble or streaming message
                    if chatStore.currentState == .aiThinking {
                        TypingBubbleView()
                            .id("typing")
                            .onAppear {
                                if lastScrollTargetId as? String != "typing" {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo("typing", anchor: .bottom)
                                    }
                                    lastScrollTargetId = "typing"
                                }
                            }
                    } else if chatStore.currentState == .streaming,
                              !chatStore.streamingContent.isEmpty {
                        StreamingMessageView(content: chatStore.streamingContent)
                            .id("streaming")
                            .onAppear {
                                if lastScrollTargetId as? String != "streaming" {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo("streaming", anchor: .bottom)
                                    }
                                    lastScrollTargetId = "streaming"
                                }
                            }
                    }

                    Color.clear.frame(height: 120) // Bottom padding
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .onAppear {
                scrollProxy = proxy
                if let lastMessage = chatStore.messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        lastScrollTargetId = lastMessage.id
                    }
                }
            }
            .onChange(of: chatStore.messages.count) { oldCount, newCount in
                if newCount > oldCount,
                   let lastMessage = chatStore.messages.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                    lastScrollTargetId = lastMessage.id
                }
            }
            .onChange(of: chatStore.streamingContent) { oldContent, newContent in
                if !newContent.isEmpty && newContent != oldContent {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                    lastScrollTargetId = "streaming"
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}


@available(iOS 26.0, *)
private struct MessageBubbleView: View {
    let message: ChatMessage
    let onLongPress: (UUID) -> Void
    @State private var showingContextMenu = false

    var body: some View {
        ChatBubble(isUser: message.isUser, timestamp: message.timestamp) {
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8)
            {
                // Message content
                Text(message.content)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                // Reactions
                if !message.reactions.isEmpty {
                    ReactionRow(reactions: message.reactions)
                }

                // Metadata (for AI messages)
                if !message.isUser, let metadata = message.metadata {
                    MessageMetadataView(metadata: metadata)
                }
            }
        }
        .contextMenu {
            MessageContextMenu(message: message)
        }
        .onLongPressGesture {
            onLongPress(message.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let sender = message.isUser ? "You" : "AI"
        let time = DateFormatter.timeFormatter.string(from: message.timestamp)
        return "\(sender) at \(time): \(message.content)"
    }
}

@available(iOS 26.0, *)
private struct StreamingMessageView: View {
    let content: String
    @State private var displayedContent = ""
    @State private var cursorVisible = true

    var body: some View {
        ChatBubble(isUser: false, timestamp: Date()) {
            HStack {
                Text(displayedContent)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(.primary)

                if cursorVisible {
                    Rectangle()
                        .fill(Color(hex: "fc9afb"))
                        .frame(width: 2, height: 20)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(
                                autoreverses: true
                            ),
                            value: cursorVisible
                        )
                }

                Spacer()
            }
        }
        .id("streaming")
        .onChange(of: content) { _, newContent in
            withAnimation(.easeOut(duration: 0.1)) {
                displayedContent = newContent
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
            ) {
                cursorVisible.toggle()
            }
        }
    }
}

@available(iOS 26.0, *)
private struct ReactionRow: View {
    let reactions: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(reactions, id: \.self) { reaction in
                Text(reaction)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }
}

@available(iOS 26.0, *)
private struct MessageMetadataView: View {
    let metadata: ChatMessage.MessageMetadata

    var body: some View {
        HStack(spacing: 8) {
            if let processingTime = metadata.processingTime {
                Text("\(String(format: "%.1f", processingTime))s")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Tokens display removed for more natural conversation flow
            // if let tokens = metadata.tokens {
            //     Text("\(tokens) tokens")
            //         .font(.caption2)
            //         .foregroundStyle(.tertiary)
            // }

            if let confidence = metadata.confidence {
                HStack(spacing: 2) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption2)
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Input Panel

@available(iOS 26.0, *)
private struct InputPanel: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var messageText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    @State private var isVoiceRecording = false

    var body: some View {
        GlassEffectContainer(
            cornerRadius: 0,
            blurRadius: 10,
            opacity: 0.4
        ) {
            VStack(spacing: 12) {
                MessageInputField(
                    messageText: $messageText,
                    isVoiceRecording: isVoiceRecording,
                    isTextFieldFocused: $isTextFieldFocused,
                    shouldShowMicButton: shouldShowMicButton,
                    canSendMessage: canSendMessage,
                    sendMessage: sendMessage,
                    startVoiceRecording: startVoiceRecording
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onChange(of: chatStore.currentState) { _, newState in
            isVoiceRecording = (newState == .voiceListening)
        }
        .onChange(of: chatStore.isRecording) { _, recording in
            isVoiceRecording = recording
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowMicButton: Bool {
        return !isTextFieldFocused && messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var canSendMessage: Bool {
        return !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func startVoiceRecording() {
        print("🎤 [InputPanel] Voice recording button tapped")
        if isVoiceRecording {
            print("🚫 [InputPanel] Stopping voice recording")
            chatStore.stopVoiceRecording()
        } else {
            print("▶️ [InputPanel] Starting voice recording")
            isTextFieldFocused = false // Dismiss keyboard
            chatStore.startVoiceRecording()
        }
    }

    private func sendMessage() {
        print("📤 [InputPanel] Send button tapped with text: '\(messageText)'")
        guard canSendMessage else { 
            print("⚠️ [InputPanel] Cannot send empty message")
            return 
        }

        let textToSend = messageText
        messageText = ""
        isTextFieldFocused = false
        
        Task {
            await chatStore.sendMessage(textToSend)
        }
    }
}

struct MessageInputField: View {
    @Binding var messageText: String
    let isVoiceRecording: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let shouldShowMicButton: Bool
    let canSendMessage: Bool

    let sendMessage: () -> Void
    let startVoiceRecording: () -> Void

    var body: some View {
        ZStack {
            TextField(
                isVoiceRecording ? "Listening..." : "Type a message...",
                text: $messageText,
                axis: .vertical
            )
            .focused($isTextFieldFocused)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .lineLimit(1...4)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.trailing, 50)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
            .submitLabel(.send)
            .onSubmit(sendMessage)

            HStack {
                Spacer()
                if shouldShowMicButton {
                    MicButton(
                        isRecording: isVoiceRecording,
                        startVoiceRecording: startVoiceRecording
                    )
                } else {
                    SendButton(
                        canSendMessage: canSendMessage,
                        sendMessage: sendMessage
                    )
                }
            }
            .padding(.trailing, 8)
        }
    }
}

struct MicButton: View {
    let isRecording: Bool
    let startVoiceRecording: () -> Void

    var body: some View {
        Button(action: startVoiceRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.title3)
                .foregroundStyle(
                    isRecording
                        ? AnyShapeStyle(.red)
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start voice recording")
    }
}

struct SendButton: View {
    let canSendMessage: Bool
    let sendMessage: () -> Void

    var body: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(
                    canSendMessage
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "fc9afb"), Color(hex: "9b6cb0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                        )
                        : AnyShapeStyle(.secondary)
                )
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .disabled(!canSendMessage)
        .accessibilityLabel("Send message")
    }
}


// MARK: - Context Menu & Reactions

@available(iOS 26.0, *)
private struct MessageContextMenu: View {
    @Environment(ChatStore.self) private var chatStore
    let message: ChatMessage

    var body: some View {
        Group {
            Button(action: { copyMessage() }) {
                Label("Copy", systemImage: "doc.on.doc")
            }

            if !message.isUser {
                Button(action: { regenerateResponse() }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }

            Button(role: .destructive, action: { deleteMessage() }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func copyMessage() {
        UIPasteboard.general.string = message.content
    }

    private func regenerateResponse() {
        // Implementation for regenerating AI response
    }

    private func deleteMessage() {
        chatStore.deleteMessage(with: message.id)
    }
}

@available(iOS 26.0, *)
private struct ReactionPickerSheet: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss
    let messageId: UUID?

    private let reactions = ["👍", "❤️", "😂", "😮", "😢", "😡", "🤔", "👏"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Reaction")
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 16
            ) {
                ForEach(reactions, id: \.self) { reaction in
                    Button(action: {
                        if let messageId = messageId {
                            chatStore.addReaction(
                                to: messageId,
                                reaction: reaction
                            )
                        }
                        dismiss()
                    }) {
                        Text(reaction)
                            .font(.largeTitle)
                            .frame(width: 60, height: 60)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Settings Sheet

@available(iOS 26.0, *)
private struct SettingsSheet: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("AI Persona") {
                    ForEach(AIPersona.allCases, id: \.self) { persona in
                        HStack {
                            Text(persona.rawValue)
                            Spacer()
                            if chatStore.settings.selectedPersona == persona {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color(hex: "fc9afb"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            chatStore.updatePersona(persona)
                        }
                    }
                }

                Section("Preferences") {
                    Toggle(
                        "Voice Input",
                        isOn: .constant(chatStore.settings.voiceEnabled)
                    )
                    Toggle(
                        "Streaming Responses",
                        isOn: .constant(chatStore.settings.streamingEnabled)
                    )
                }

                Section {
                    Button("Start New Conversation") {
                        chatStore.startNewSession()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Typing Bubble

@available(iOS 26.0, *)
private struct TypingBubbleView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        ChatBubble(isUser: false, timestamp: Date()) {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(hex: "9b6cb0"))
                        .frame(width: 8, height: 8)
                        .scaleEffect(
                            animationPhase == index ? 1.4 : 0.8
                        )
                        .opacity(
                            animationPhase == index ? 1.0 : 0.6
                        )
                        .animation(.easeInOut(duration: 0.4), value: animationPhase)
                }
                
                // Add some spacing to make it look more like a message
                Spacer().frame(width: 20)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .id("typing")
        .onAppear {
            startTypingAnimation()
        }
        .accessibilityLabel("AI is typing")
    }
    
    private func startTypingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
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
