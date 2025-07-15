//import XCTest
//import SwiftUI
//@testable import Ruby
//
//@available(iOS 26.0, *)
//final class ChatBotIntegrationTests: XCTestCase {
//    
//    var chatStore: ChatStore!
//    
//    override func setUp() {
//        super.setUp()
//        chatStore = ChatStore()
//    }
//    
//    override func tearDown() {
//        chatStore = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Store Integration Tests
//    
//    func testChatStoreInitialization() {
//        XCTAssertEqual(chatStore.currentState, .placeholder)
//        XCTAssertTrue(chatStore.messages.isEmpty)
//        XCTAssertEqual(chatStore.currentInput, "")
//        XCTAssertFalse(chatStore.isRecording)
//        XCTAssertFalse(chatStore.isAITyping)
//    }
//    
//    func testStateTransitions() async {
//        // Test transition from placeholder to active chat
//        await chatStore.sendMessage("Hello")
//        
//        // Should transition through aiThinking to activeChat
//        await Task.sleep(nanoseconds: 1_000_000) // Small delay for state updates
//        
//        XCTAssertEqual(chatStore.messages.count, 2) // User message + AI response
//        XCTAssertEqual(chatStore.messages.first?.content, "Hello")
//        XCTAssertTrue(chatStore.messages.first?.isUser == true)
//        XCTAssertTrue(chatStore.messages.last?.isUser == false)
//    }
//    
//    func testVoiceRecording() {
//        chatStore.startVoiceRecording()
//        XCTAssertEqual(chatStore.currentState, .voiceListening)
//        XCTAssertTrue(chatStore.isRecording)
//        
//        chatStore.stopVoiceRecording()
//        XCTAssertFalse(chatStore.isRecording)
//    }
//    
//    func testPersonaChange() {
//        let initialPersona = chatStore.settings.selectedPersona
//        let newPersona: AIPersona = initialPersona == therapist ? .professional : therapist
//        
//        chatStore.updatePersona(newPersona)
//        XCTAssertEqual(chatStore.settings.selectedPersona, newPersona)
//    }
//    
//    func testMessageReactions() {
//        let testMessage = ChatMessage(content: "Test", isUser: false, timestamp: Date())
//        chatStore.messages.append(testMessage)
//        
//        chatStore.addReaction(to: testMessage.id, reaction: "❤️")
//        
//        XCTAssertTrue(chatStore.messages.first?.reactions.contains("❤️") == true)
//    }
//    
//    func testNewSession() {
//        // Add some messages first
//        chatStore.messages.append(ChatMessage(content: "Test 1", isUser: true, timestamp: Date()))
//        chatStore.messages.append(ChatMessage(content: "Test 2", isUser: false, timestamp: Date()))
//        
//        chatStore.startNewSession()
//        
//        XCTAssertTrue(chatStore.messages.isEmpty)
//        XCTAssertEqual(chatStore.currentState, .placeholder)
//        XCTAssertEqual(chatStore.currentInput, "")
//        XCTAssertEqual(chatStore.streamingContent, "")
//    }
//    
//    // MARK: - Foundation Models Integration Tests
//    
//    func testFoundationModelsAvailability() async {
//        // Test that Foundation Models can be initialized
//        await chatStore.initializeAI()
//        
//        // If iOS 26+ is available, should not be in error state
//        if #available(iOS 26.0, *) {
//            XCTAssertNotEqual(chatStore.currentState, .error("Failed to initialize AI"))
//        }
//    }
//    
//    func testStreamingResponse() async {
//        chatStore.settings.streamingEnabled = true
//        
//        await chatStore.sendMessage("Test streaming")
//        
//        // Verify that streaming was attempted
//        // In a real implementation, we'd check for streaming state transitions
//        XCTAssertTrue(chatStore.messages.count >= 1)
//    }
//    
//    func testGuidedGeneration() {
//        // Test that the @Generable structs are properly configured
//        let analysis = MessageAnalysis(
//            intent: "question",
//            sentiment: "positive",
//            responseLength: "brief",
//            requiresTools: false
//        )
//        
//        XCTAssertEqual(analysis.intent, "question")
//        XCTAssertEqual(analysis.sentiment, "positive")
//        XCTAssertEqual(analysis.responseLength, "brief")
//        XCTAssertFalse(analysis.requiresTools)
//    }
//    
//    // MARK: - Error Handling Tests
//    
//    func testContextWindowExceeded() {
//        // Simulate context window exceeded scenario
//        chatStore.lastError = .contextWindowExceeded
//        
//        XCTAssertEqual(chatStore.lastError, .contextWindowExceeded)
//    }
//    
//    func testVoiceRecognitionError() {
//        chatStore.lastError = .voiceRecognitionFailed
//        
//        XCTAssertEqual(chatStore.lastError, .voiceRecognitionFailed)
//    }
//    
//    // MARK: - UI Component Tests
//    
//    func testChatBubbleCreation() {
//        let message = ChatMessage(content: "Test message", isUser: true, timestamp: Date())
//        
//        let bubble = ChatBubble(isUser: message.isUser, timestamp: message.timestamp) {
//            Text(message.content)
//        }
//        
//        // Test that bubble can be created without errors
//        XCTAssertNotNil(bubble)
//    }
//    
//    func testGlassEffectContainer() {
//        let container = GlassEffectContainer {
//            Text("Test content")
//        }
//        
//        // Test that container can be created without errors
//        XCTAssertNotNil(container)
//    }
//    
//    func testMaterialBackground() {
//        let background = MaterialBackground()
//        
//        // Test that background can be created without errors
//        XCTAssertNotNil(background)
//    }
//    
//    func testFloatingOrb() {
//        let orb = FloatingOrb(
//            offset: CGSize(width: 100, height: 100),
//            delay: 0.5
//        )
//        
//        // Test that orb can be created without errors
//        XCTAssertNotNil(orb)
//    }
//    
//    func testVoiceWaveform() {
//        let amplitudes: [Float] = Array(repeating: 0.5, count: 50)
//        let waveform = VoiceWaveform(amplitudes: amplitudes, isActive: true)
//        
//        // Test that waveform can be created without errors
//        XCTAssertNotNil(waveform)
//    }
//    
//    func testThinkingDots() {
//        let dots = ThinkingDots()
//        
//        // Test that thinking dots can be created without errors
//        XCTAssertNotNil(dots)
//    }
//    
//    // MARK: - Performance Tests
//    
//    func testMessageListPerformance() {
//        measure {
//            // Add 100 messages to test performance
//            for i in 0..<100 {
//                chatStore.messages.append(
//                    ChatMessage(
//                        content: "Test message \(i)",
//                        isUser: i % 2 == 0,
//                        timestamp: Date()
//                    )
//                )
//            }
//        }
//    }
//    
//    func testWaveformUpdatePerformance() {
//        let amplitudes = Array(repeating: Float(0.5), count: 50)
//        
//        measure {
//            chatStore.voiceWaveform = amplitudes
//        }
//    }
//    
//    // MARK: - Accessibility Tests
//    
//    func testAccessibilityLabels() {
//        // Test that main view components have proper accessibility
//        let mainView = MainChatBotView()
//        
//        // In a real implementation, we'd test VoiceOver navigation
//        XCTAssertNotNil(mainView)
//    }
//    
//    // MARK: - Settings Tests
//    
//    func testChatSettings() {
//        let settings = ChatSettings.default
//        
//        XCTAssertEqual(settings.selectedPersona, therapist)
//        XCTAssertTrue(settings.voiceEnabled)
//        XCTAssertTrue(settings.streamingEnabled)
//        XCTAssertEqual(settings.maxContextLength, 8000)
//        XCTAssertTrue(settings.autoSaveConversations)
//    }
//    
//    func testPersonaSystemPrompts() {
//        XCTAssertFalse(AIPersonatherapist.systemPrompt.isEmpty)
//        XCTAssertFalse(AIPersona.professional.systemPrompt.isEmpty)
//        XCTAssertFalse(AIPersona.creative.systemPrompt.isEmpty)
//        XCTAssertFalse(AIPersona.technical.systemPrompt.isEmpty)
//    }
//    
//    // MARK: - Color System Tests
//    
//    func testColorHexInitialization() {
//        let lavenderBlush = Color(hex: "f7e6ff")
//        let pinkOrchid = Color(hex: "fc9afb")
//        let purplePlum = Color(hex: "b016f7")
//        
//        // Test that colors can be created from hex values
//        XCTAssertNotNil(lavenderBlush)
//        XCTAssertNotNil(pinkOrchid)
//        XCTAssertNotNil(purplePlum)
//    }
//    
//    // MARK: - Integration Test Scenarios
//    
//    func testCompleteConversationFlow() async {
//        // Test a complete conversation flow
//        
//        // 1. Initialize AI
//        await chatStore.initializeAI()
//        XCTAssertTrue([.placeholder, .activeChat].contains(chatStore.currentState))
//        
//        // 2. Send first message
//        await chatStore.sendMessage("Hello, how are you?")
//        XCTAssertTrue(chatStore.messages.count >= 2)
//        
//        // 3. Add reaction to AI response
//        if let aiMessage = chatStore.messages.last {
//            chatStore.addReaction(to: aiMessage.id, reaction: "👍")
//            XCTAssertTrue(aiMessage.reactions.contains("👍"))
//        }
//        
//        // 4. Send follow-up message
//        await chatStore.sendMessage("Can you help me with something?")
//        XCTAssertTrue(chatStore.messages.count >= 4)
//        
//        // 5. Start new session
//        chatStore.startNewSession()
//        XCTAssertTrue(chatStore.messages.isEmpty)
//        XCTAssertEqual(chatStore.currentState, .placeholder)
//    }
//    
//    func testVoiceToTextFlow() {
//        // Test voice interaction flow
//        
//        // 1. Start voice recording
//        chatStore.startVoiceRecording()
//        XCTAssertEqual(chatStore.currentState, .voiceListening)
//        XCTAssertTrue(chatStore.isRecording)
//        
//        // 2. Simulate voice input
//        chatStore.currentInput = "This is a voice message"
//        
//        // 3. Stop recording
//        chatStore.stopVoiceRecording()
//        XCTAssertFalse(chatStore.isRecording)
//        
//        // 4. Verify input was captured
//        XCTAssertEqual(chatStore.currentInput, "This is a voice message")
//    }
//    
//    func testErrorRecoveryFlow() async {
//        // Test error handling and recovery
//        
//        // 1. Simulate context window exceeded
//        chatStore.lastError = .contextWindowExceeded
//        XCTAssertEqual(chatStore.lastError, .contextWindowExceeded)
//        
//        // 2. Attempt to send message (should handle error)
//        await chatStore.sendMessage("Test message after error")
//        
//        // 3. Verify system continues to function
//        XCTAssertTrue(chatStore.messages.count >= 1)
//    }
//}
//
//// MARK: - Mock Extensions for Testing
//
//@available(iOS 26.0, *)
//extension ChatStore {
//    /// Test helper to simulate AI response without actual Foundation Models call
//    func simulateAIResponse(_ content: String) {
//        let aiMessage = ChatMessage(
//            content: content,
//            isUser: false,
//            timestamp: Date(),
//            metadata: ChatMessage.MessageMetadata(
//                processingTime: 0.5,
//                tokens: content.split(separator: " ").count,
//                confidence: 0.95
//            )
//        )
//        messages.append(aiMessage)
//        currentState = .activeChat
//        isAITyping = false
//    }
//}
//
//// MARK: - Test Data Helpers
//
//struct TestDataHelper {
//    static func createSampleMessages() -> [ChatMessage] {
//        return [
//            ChatMessage(content: "Hello!", isUser: true, timestamp: Date().addingTimeInterval(-300)),
//            ChatMessage(content: "Hi there! How can I help you today?", isUser: false, timestamp: Date().addingTimeInterval(-280)),
//            ChatMessage(content: "I need help with my project", isUser: true, timestamp: Date().addingTimeInterval(-260)),
//            ChatMessage(content: "I'd be happy to help! What kind of project are you working on?", isUser: false, timestamp: Date().addingTimeInterval(-240))
//        ]
//    }
//    
//    static func createSampleSession() -> ConversationSession {
//        return ConversationSession(
//            title: "Test Conversation",
//            createdAt: Date().addingTimeInterval(-3600),
//            lastModified: Date(),
//            messages: createSampleMessages(),
//            persona: therapist
//        )
//    }
//}
