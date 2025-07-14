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
                .foregroundStyle(.black)
        }
    }

    private var statusColor: Color {
        switch chatStore.currentState {
        case .activeChat:
            return Color.green.opacity(1.0)
        case .aiThinking:
            return Color(hex: "fc9afb")
        case .streaming:
            return Color(hex: "9b6cb0")
        case .voiceListening:
            return .blue
        case .error:
            return .red
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
        case .error(let message):
            return "Error"
        }
    }
}

// MARK: - Messages List

@available(iOS 26.0, *)
private struct MessagesList: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var selectedMessageId: UUID?
    @Binding var showingReactionPicker: Bool

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                let sortedMessages = chatStore.messages.sorted {
                    $0.timestamp < $1.timestamp
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedMessages) { message in
                        MessageBubbleView(
                            message: message,
                            onLongPress: { messageId in
                                selectedMessageId = messageId
                                showingReactionPicker = true
                            }
                        )
                        .id(message.id)
                    }

                    // AI typing bubble when thinking
                    if chatStore.currentState == .aiThinking {
                        TypingBubbleView()
                            .id("live_response")
                    }

                    // Streaming content when AI is responding
                    if chatStore.currentState == .streaming
                        && !chatStore.streamingContent.isEmpty
                    {
                        StreamingMessageView(
                            content: chatStore.streamingContent
                        )
                        .id("live_response")
                    }

                    Color.clear.frame(height: 16).id("bottom_padding")
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .onChange(of: chatStore.messages.count) { _, _ in
                withAnimation {
                    scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
                }
            }
            .onChange(of: chatStore.streamingContent) { _, _ in
                if !chatStore.streamingContent.isEmpty {
                    withAnimation {
                        scrollViewProxy.scrollTo(
                            "bottom_padding",
                            anchor: .bottom
                        )
                    }
                }
            }
            .onChange(of: chatStore.currentState) { _, newState in
                if newState == .aiThinking || newState == .streaming {
                    withAnimation {
                        scrollViewProxy.scrollTo(
                            "bottom_padding",
                            anchor: .bottom
                        )
                    }
                }
            }
            .onAppear {
                scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
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
    @State private var realTimeTranscription = ""

    var body: some View {

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
        .padding(.vertical, 4)
        .onChange(of: chatStore.currentState) { _, newState in
            isVoiceRecording = (newState == .voiceListening)
        }
        .onChange(of: chatStore.isRecording) { _, recording in
            isVoiceRecording = recording
            if !recording {
                realTimeTranscription = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VoiceTranscriptionUpdate"))) { notification in
            if let transcription = notification.object as? String {
                realTimeTranscription = transcription
                // Update the message text with real-time transcription during recording
                if isVoiceRecording {
                    messageText = transcription
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var shouldShowMicButton: Bool {
        return !isTextFieldFocused
            && messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    private var canSendMessage: Bool {
        return !messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Actions

    private func startVoiceRecording() {
        print("🎤 [InputPanel] Voice recording button tapped")
        if isVoiceRecording {
            print("🚫 [InputPanel] Stopping voice recording")
            chatStore.stopVoiceRecording()
        } else {
            print("▶️ [InputPanel] Starting voice recording")
            isTextFieldFocused = false  // Dismiss keyboard
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

    @State private var textHeight: CGFloat = 44
    private let minHeight: CGFloat = 44
    private let maxHeight: CGFloat = 100

    var body: some View {
        ZStack {
            // Main text field container with unified background
            HStack(spacing: 0) {
                // Text field with proper containment for select all bubble
                ZStack(alignment: .topLeading) {
                    TextField(
                        isVoiceRecording ? "Listening..." : "Ask anything",
                        text: $messageText,
                        axis: .vertical
                    )
                    .focused($isTextFieldFocused)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .lineLimit(nil)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.send)
                    .onSubmit {
                        if !messageText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {
                            sendMessage()
                        }
                    }
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: minHeight - 24, maxHeight: maxHeight - 24)
                    .padding(.leading, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 44)
                    .clipped() // Ensure select all bubble stays within bounds
                    .contentShape(Rectangle()) // Proper hit testing
                    
                    // Invisible overlay to ensure proper text positioning
                    if messageText.isEmpty {
                        HStack {
                            Text("Ask anything")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.leading, 16)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
            .background(
                // Hidden text for height calculation
                GeometryReader { geometry in
                    Text(messageText.isEmpty ? " " : messageText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .onAppear {
                            updateHeight(from: geometry)
                        }
                        .onChange(of: messageText) { _, _ in
                            updateHeight(from: geometry)
                        }
                        .opacity(0)
                }
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: min(textHeight / 2, 22))
            )
            
            // Integrated button on the right
            HStack {
                Spacer()
                if shouldShowMicButton {
                    IntegratedMicButton(
                        isRecording: isVoiceRecording,
                        startVoiceRecording: startVoiceRecording
                    )
                } else {
                    IntegratedSendButton(
                        canSendMessage: canSendMessage,
                        sendMessage: sendMessage
                    )
                }
            }
            .padding(.trailing, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func updateHeight(from geometry: GeometryProxy) {
        let newHeight = max(minHeight, min(maxHeight, geometry.size.height))
        if abs(textHeight - newHeight) > 1 {
            withAnimation(.easeOut(duration: 0.15)) {
                textHeight = newHeight
            }
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
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .accessibilityLabel(
            isRecording ? "Stop recording" : "Start voice recording"
        )
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
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
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

// MARK: - Integrated Buttons

struct IntegratedMicButton: View {
    let isRecording: Bool
    let startVoiceRecording: () -> Void

    var body: some View {
        Button(action: startVoiceRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.title3)
                .foregroundStyle(
                    isRecording
                        ? AnyShapeStyle(.red)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .frame(width: 32, height: 32)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .accessibilityLabel(
            isRecording ? "Stop recording" : "Start voice recording"
        )
    }
}

struct IntegratedSendButton: View {
    let canSendMessage: Bool
    let sendMessage: () -> Void

    var body: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(
                    canSendMessage
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(.secondary)
                )
                .frame(width: 32, height: 32)
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
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: animationPhase
                        )
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

// MARK: - Chat History Sheet

@available(iOS 26.0, *)
private struct ChatHistorySheet: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with blur effect for inactive area
                MaterialBackground(intensity: 0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Chat history list
                    List {
                        ForEach(filteredSessions, id: \.id) { session in
                            ChatHistoryRow(
                                session: session,
                                onTap: {
                                    Task {
                                        await chatStore.loadSession(session)
                                        dismiss()
                                    }
                                },
                                onDelete: {
                                    chatStore.deleteSession(session)
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        showingDeleteAlert = true
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "fc9afb"))
                }
            }
            .alert("Clear All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    // Clear all chat history
                    for session in chatStore.savedSessions {
                        chatStore.deleteSession(session)
                    }
                }
            } message: {
                Text("This will permanently delete all chat history. This action cannot be undone.")
            }
        }
    }
    
    private var filteredSessions: [ConversationSession] {
        if searchText.isEmpty {
            return chatStore.savedSessions
        } else {
            return chatStore.savedSessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

@available(iOS 26.0, *)
private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search conversations...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

@available(iOS 26.0, *)
private struct ChatHistoryRow: View {
    let session: ConversationSession
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(truncatedTitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(session.lastMessage?.content ?? "No messages")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(session.lastModified, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    Text("\(session.messageCount) messages")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private var truncatedTitle: String {
        if session.title.count > 40 {
            return String(session.title.prefix(40)) + "..."
        }
        return session.title
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    ActiveChatStateView()
        .environment(ChatStore())
}
