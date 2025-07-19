import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
final class ChatCoordinator {
    // MARK: - Managers
    
    let sessionManager: ChatSessionManager
    @ObservationIgnored
    lazy var aiManager: ChatAIManager = {
        ChatAIManager(toolRegistry: ChatToolRegistry())
    }()
    let voiceManager: ChatVoiceManager
    let uiManager: ChatUIManager
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatCoordinator")
    private var sessionTitleUpdateTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(dataManager: DataManager = DataManager.shared) {
        let toolRegistry = ChatToolRegistry()
        self.sessionManager = ChatSessionManager(dataManager: dataManager)
        self.voiceManager = ChatVoiceManager()
        self.uiManager = ChatUIManager(dataManager: dataManager)
        self.aiManager = ChatAIManager(toolRegistry: toolRegistry)

        logger.info("🔧 [ChatCoordinator] Initializing ChatCoordinator with tool registry")
        
        Task {
            await initialize()
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        logger.info("🚀 [ChatCoordinator] Starting initialization")
        
        do {
            try await aiManager.initializeAI()
            
            // Initialize new session if none exists
            if sessionManager.currentSession == nil {
                await startNewSession()
            } else {
                // Load existing session messages into UI
                if let session = sessionManager.currentSession {
                    uiManager.updateMessages(session.messages)
                    aiManager.updateInstructions(session.persona.systemPrompt)
                }
            }
            
            logger.info("✅ [ChatCoordinator] Initialization completed successfully")
            
        } catch {
            logger.error("❌ [ChatCoordinator] Initialization failed: \(error.localizedDescription)")
            uiManager.setError(.other)
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession() async {
        logger.info("🆕 [ChatCoordinator] Starting new chat session")
        
        await sessionManager.startNewSession(with: uiManager.settings.selectedPersona)
        
        // Reset UI state
        uiManager.resetMessages()
        uiManager.setState(.activeChat)
        uiManager.clearError()
        aiManager.reset()
        
        // Add greeting message to UI
        if let session = sessionManager.currentSession {
            uiManager.updateMessages(session.messages)
            aiManager.updateInstructions(session.persona.systemPrompt)
        }
        
        logger.info("✅ [ChatCoordinator] New session started")
    }
    
    func loadSession(_ session: ConversationSession) async {
        logger.info("📁 [ChatCoordinator] Loading session: \(session.id)")
        
        await sessionManager.loadSession(session)
        
        // Update UI
        uiManager.updateMessages(session.messages)
        uiManager.updatePersona(session.persona)
        uiManager.setState(.activeChat)
        uiManager.clearError()
        aiManager.reset()
        aiManager.updateInstructions(session.persona.systemPrompt)
        
        logger.info("✅ [ChatCoordinator] Session loaded successfully")
    }
    
    func deleteSession(_ session: ConversationSession) async {
        logger.info("🗑️ [ChatCoordinator] Deleting session: \(session.id)")
        
        do {
            try await sessionManager.deleteSession(session)
            
            // If deleting current session, start new one
            if sessionManager.currentSession?.id == session.id {
                await startNewSession()
            }
            
            logger.info("✅ [ChatCoordinator] Session deleted successfully")
            
        } catch {
            logger.error("❌ [ChatCoordinator] Failed to delete session: \(error.localizedDescription)")
            uiManager.setError(.other)
        }
    }
    
    // MARK: - Message Management
    
    func sendMessage(_ content: String, useStreaming: Bool = true) async {
        logger.info("📤 [ChatCoordinator] Sending message")
        
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true, timestamp: Date())
        uiManager.addMessage(userMessage)
        
        // Update session with new message
        await sessionManager.updateSessionMessages(uiManager.messages)
        
        // Generate AI response using strategy pattern
        await generateAIResponse(for: content)
        
        // Generate title for new sessions
        if let session = sessionManager.currentSession,
           session.title == "New Conversation",
           session.messages.filter({ $0.isUser }).count == 1 {
            await updateSessionTitle()
        }
    }
    
    func addReaction(to messageId: UUID, reaction: String) async {
        uiManager.addReaction(to: messageId, reaction: reaction)
        await sessionManager.updateSessionMessages(uiManager.messages)
    }
    
    func deleteMessage(_ message: ChatMessage) async {
        uiManager.deleteMessage(message)
        
        // If no messages left, add a default greeting
        if uiManager.messages.isEmpty {
            let greetingMessage = createGreetingMessage()
            uiManager.addMessage(greetingMessage)
        }
        
        await sessionManager.updateSessionMessages(uiManager.messages)
    }
    
    // MARK: - Voice Recording
    
    func startVoiceRecording() async {
        logger.info("🎤 [ChatCoordinator] Starting voice recording")
        
        do {
            try await voiceManager.startVoiceRecording()
            uiManager.setState(.voiceListening)
        } catch {
            logger.error("❌ [ChatCoordinator] Failed to start voice recording: \(error.localizedDescription)")
            uiManager.setError(.other)
        }
    }
    
    func stopVoiceRecording() async {
        logger.info("🛑 [ChatCoordinator] Stopping voice recording")
        
        let transcription = voiceManager.stopVoiceRecording()
        uiManager.setState(.activeChat)
        
        if !transcription.isEmpty {
            await sendMessage(transcription)
        }
    }
    
    // MARK: - Settings Management
    
    func updatePersona(_ persona: AIPersona) async {
        logger.info("👤 [ChatCoordinator] Updating persona to: \(persona.rawValue)")
        
        uiManager.updatePersona(persona)
        aiManager.updateInstructions(persona.systemPrompt)
        await sessionManager.updateSessionPersona(persona)
    }
    
    func updateSettings(_ settings: ChatSettings) async {
        logger.info("⚙️ [ChatCoordinator] Updating settings")
        
        let oldPersona = uiManager.settings.selectedPersona
        uiManager.updateSettings(settings)
        
        // If persona changed, update AI instructions and session
        if oldPersona != settings.selectedPersona {
            aiManager.updateInstructions(settings.selectedPersona.systemPrompt)
            await sessionManager.updateSessionPersona(settings.selectedPersona)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateAIResponse(for input: String) async {
        logger.info("🤖 [ChatCoordinator] Generating AI response using strategy pattern")
        
        uiManager.setState(.aiThinking)
        
        do {
            // Create response context
            let context = ResponseContext(
                input: input,
                persona: uiManager.settings.selectedPersona,
                messageCount: uiManager.messages.count,
                settings: uiManager.settings
            )
            
            // Set appropriate state based on strategy
            if context.recommendedStrategy == .streaming {
                uiManager.setState(.streaming)
            }
            
            let response = try await aiManager.generateResponse(
                for: input,
                context: context
            ) { partialContent in
                // Streaming updates are handled by the AI manager's streamingContent property
            }
            
            uiManager.addMessage(response)
            await sessionManager.updateSessionMessages(uiManager.messages)
            uiManager.setState(.activeChat)
            
        } catch {
            logger.error("❌ [ChatCoordinator] AI response failed: \(error.localizedDescription)")
            if let chatError = error as? ChatError {
                uiManager.setError(chatError)
            } else {
                uiManager.setError(.other)
            }
        }
    }
    
    private func updateSessionTitle() async {
        guard let session = sessionManager.currentSession,
              let firstUserMessage = session.messages.first(where: { $0.isUser })?.content else {
            return
        }
        
        logger.info("📝 [ChatCoordinator] Generating title for session: \(session.id)")
        
        // Cancel any pending title update
        sessionTitleUpdateTask?.cancel()
        
        sessionTitleUpdateTask = Task {
            do {
                let title = try await aiManager.generateSessionTitle(for: firstUserMessage)
                await sessionManager.updateSessionTitle(title)
                logger.info("📋 [ChatCoordinator] Session title updated: '\(title)'")
            } catch {
                logger.error("❌ [ChatCoordinator] Failed to generate session title: \(error.localizedDescription)")
            }
        }
    }
    
    private func createGreetingMessage() -> ChatMessage {
        let greeting: String
        
        switch uiManager.settings.selectedPersona {
        case .none:
            greeting = "What's shakin, bacon?"
        case .therapist:
            greeting = "Hi there! What's on your mind today?"
        case .professor:
            greeting = "Hello! What would you like to explore and learn about today?"
        case .techLead:
            greeting = "Hey! What technical challenge can I help you tackle today?"
        case .musician:
            greeting = "Hello! Ready to dive into the world of music and creativity?"
        case .comedian:
            greeting = "Hey there! What's bringing you joy or stress today? Let's find the humor in it!"
        }
        
        return ChatMessage(
            content: greeting,
            isUser: false,
            timestamp: Date()
        )
    }
    
    // MARK: - Export/Import
    
    func exportSession(_ session: ConversationSession) -> Data? {
        return sessionManager.exportSession(session)
    }
    
    func importSession(from data: Data) async {
        do {
            try await sessionManager.importSession(from: data)
            logger.info("✅ [ChatCoordinator] Session imported successfully")
        } catch {
            logger.error("❌ [ChatCoordinator] Failed to import session: \(error.localizedDescription)")
            uiManager.setError(.other)
        }
    }
    
    func clearAllData() async {
        logger.info("🗑️ [ChatCoordinator] Clearing all data")
        
        do {
            try await sessionManager.clearAllData()
            await startNewSession()
            logger.info("✅ [ChatCoordinator] All data cleared successfully")
        } catch {
            logger.error("❌ [ChatCoordinator] Failed to clear all data: \(error.localizedDescription)")
            uiManager.setError(.other)
        }
    }
    
    func shutdown() {
        logger.info("🔥 [ChatCoordinator] ChatCoordinator deinitializing")
        sessionTitleUpdateTask?.cancel()
    }
}
