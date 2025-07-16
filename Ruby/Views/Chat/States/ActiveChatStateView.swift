import SwiftUI
import FoundationModels

/// The main chat interface with scrollable message list, input panel,
/// message reactions support, and long press context menus
@available(iOS 26.0, *)
struct ActiveChatStateView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var messageText = ""
    @State private var selectedMessageId: UUID?
    @State private var showingReactionPicker = false
    @State private var showingChatHistory = false
    @FocusState private var isTextFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var pendingMessage: String?
    @State private var streamingContent = ""

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
            await generateAIResponse(for: message)
            pendingMessage = nil
        }
    }
    
    // MARK: - Message Handling Functions
    
    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message immediately
        let userMessage = ChatMessage(content: text, isUser: true, timestamp: Date())
        chatStore.addMessage(userMessage)
        
        // Set pending message to trigger AI response
        pendingMessage = text
    }
    
    private func generateAIResponse(for input: String) async {
        let startTime = Date()
        print("🤖 [AI-TRIGGER] AI model triggered with user input: '\(input)'")
        print("🔧 [AI-CONFIG] Using streaming: \(chatStore.settings.streamingEnabled), temperature: \(chatStore.generationOptions.temperature)")
        print("👤 [AI-PERSONA] Active persona: \(chatStore.settings.selectedPersona.rawValue)")
        print("📝 [AI-CONTEXT] Message count in session: \(chatStore.messages.count)")
        
        chatStore.currentState = .aiThinking
        streamingContent = ""
        
        do {
            if chatStore.settings.streamingEnabled {
                print("🌊 [AI-MODE] Starting streaming response generation")
                await generateStreamingResponse(for: input)
            } else {
                print("📄 [AI-MODE] Starting complete response generation")
                await generateCompleteResponse(for: input)
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            print("✅ [AI-COMPLETE] AI response completed in \(String(format: "%.2f", processingTime))s")
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            print("❌ [AI-ERROR] AI response failed after \(String(format: "%.2f", processingTime))s: \(error)")
            chatStore.currentState = .activeChat
            // Add error message
            let errorMessage = ChatMessage(
                content: "I'm having trouble responding right now. Please try again.",
                isUser: false,
                timestamp: Date()
            )
            chatStore.addMessage(errorMessage)
        }
    }
    
    private func generateStreamingResponse(for input: String) async {
        chatStore.currentState = .streaming
        
        do {
            print("🔧 [STREAM-INIT] Initializing streaming session with LanguageModelSession")
            print("⚙️ [STREAM-OPTIONS] Temperature: \(GenerationOptionsFlavors.default.temperature ?? 1.0)")
            print("📋 [FINAL-PROMPT] User input being sent to model: '\(input)'")
            
            let stream = chatStore.publicLanguageSession.streamResponse(
                options: GenerationOptionsFlavors.default
            ) {
                input
            }
            
            print("🌊 [STREAM-START] Stream connection established, beginning content generation")
            streamingContent = ""
            var chunkCount = 0
            
            // Process streaming response
            for try await partialStream in stream {
                chunkCount += 1
                streamingContent = partialStream
                chatStore.streamingContent = partialStream
                
                if chunkCount == 1 {
                    print("📝 [STREAM-FIRST] First chunk received, streaming has begun")
                } else if chunkCount % 10 == 0 {
                    print("📊 [STREAM-PROGRESS] Received \(chunkCount) chunks, current length: \(streamingContent.count) chars")
                }
            }
            
            print("🏁 [STREAM-END] Streaming completed, total chunks: \(chunkCount), final content length: \(streamingContent.count)")
            
            // Check for tool usage by looking for common tool indicators
            let hasToolUsage = streamingContent.contains("weather") || streamingContent.contains("search") || 
                              streamingContent.contains("calculator") || streamingContent.contains("reminder") ||
                              streamingContent.contains("news") || streamingContent.contains("tool")
            
            if hasToolUsage {
                print("🔧 [TOOL-DETECTED] AI response appears to include tool usage or tool-generated content")
            }
            
            // Finalize streaming message
            if !streamingContent.isEmpty {
                print("💾 [STREAM-SAVE] Saving streamed AI response to chat history")
                let finalMessage = ChatMessage(
                    content: streamingContent,
                    isUser: false,
                    timestamp: Date()
                )
                chatStore.addMessage(finalMessage)
                chatStore.streamingContent = nil
                print("✅ [STREAM-SUCCESS] Streamed response saved successfully")
            } else {
                print("⚠️ [STREAM-EMPTY] No content received from streaming, this is unusual")
            }
            
            chatStore.currentState = .activeChat
            
        } catch {
            print("❌ [STREAM-ERROR] Streaming response failed: \(error)")
            print("🔍 [STREAM-ERROR-DETAIL] Error type: \(type(of: error)), description: \(error.localizedDescription)")
        }
    }
    
    private func generateCompleteResponse(for input: String) async {
        do {
            print("🔧 [COMPLETE-INIT] Initializing complete response with LanguageModelSession")
            print("⚙️ [COMPLETE-OPTIONS] Temperature: \(chatStore.generationOptions.temperature ?? 1.0)")
            print("📋 [FINAL-PROMPT] User input being sent to model: '\(input)'")
            print("🎯 [RESPONSE-TYPE] Generating structured ChatResponse with content, tone, and confidence")
            
            let responseStartTime = Date()
            let response = try await chatStore.publicLanguageSession.respond(
                to: input,
                generating: ChatResponse.self,
                options: GenerationOptions(
                    temperature: chatStore.generationOptions.temperature
                )
            )
            let responseTime = Date().timeIntervalSince(responseStartTime)
            
            print("📥 [AI-RESPONSE] Received complete response in \(String(format: "%.2f", responseTime))s")
            print("📝 [AI-CONTENT] Content: '\(response.content.content)'")
            print("🎭 [AI-TONE] Detected tone: '\(response.content.tone)'")
            print("📊 [AI-CONFIDENCE] Confidence score: \(String(format: "%.2f", response.content.confidence))")
            
            // Check for tool usage by looking for common tool indicators
            let hasToolUsage = response.content.content.contains("weather") || response.content.content.contains("search") || 
                              response.content.content.contains("calculator") || response.content.content.contains("reminder") ||
                              response.content.content.contains("news") || response.content.content.contains("tool")
            
            if hasToolUsage {
                print("🔧 [TOOL-DETECTED] AI response appears to include tool usage or tool-generated content")
            }
            
            // Add AI response to messages
            print("💾 [COMPLETE-SAVE] Saving complete AI response to chat history")
            let aiMessage = ChatMessage(
                content: response.content.content,
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: responseTime,
                    tokens: nil,
                    confidence: response.content.confidence
                )
            )
            
            chatStore.addMessage(aiMessage)
            chatStore.currentState = .activeChat
            print("✅ [COMPLETE-SUCCESS] Complete response saved successfully")
            
        } catch {
            print("❌ [COMPLETE-ERROR] Complete response failed: \(error)")
            print("🔍 [COMPLETE-ERROR-DETAIL] Error type: \(type(of: error)), description: \(error.localizedDescription)")
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
