import Foundation
import SwiftUI
import FoundationModels
import os.log
import Observation

@Observable
@MainActor
final class ChatAIManager {
    // MARK: - Properties
    
    var streamingContent: String? = nil
    var isProcessing: Bool = false
    let toolRegistry: ChatToolRegistry
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatAIManager")
    private var isInitialized = false
    @ObservationIgnored
    private var languageSession: LanguageModelSession = {
        LanguageModelSession()
    }()
    @ObservationIgnored
    private var transcript: Transcript?
    @ObservationIgnored
    private lazy var titleGenerationSession: LanguageModelSession = {
        LanguageModelSession()
    }()
    
    var publicLanguageSession: LanguageModelSession? {
        languageSession
    }
    
    // MARK: - Initialization
    
    init(toolRegistry: ChatToolRegistry, initialPersona: AIPersona = .none) {
        self.toolRegistry = toolRegistry
        logger.info("🔧 [ChatAIManager] Initializing ChatAIManager with tool registry")
        createLanguageSession(with: initialPersona.systemPrompt)
    }
    
    // MARK: - AI Management
    
    func initializeAI() async throws {
        logger.info("🚀 [ChatAIManager] Starting AI initialization")
        
        do {
            self.isInitialized = true
            logger.info("✅ [ChatAIManager] AI initialization completed successfully")
        } catch {
            logger.error("❌ [ChatAIManager] AI initialization failed: \(error.localizedDescription)")
        }
    }
    
    func updateInstructions(_ instructions: String) {
        logger.info("📝 [ChatAIManager] Updating instructions with based on system prompt: \(instructions.prefix(100))...")
        createLanguageSession(with: instructions)
    }
    
    private func createLanguageSession(with instructions: String = "") {
        let enabledTools = toolRegistry.getEnabledTools()
        languageSession = LanguageModelSession(
            tools: enabledTools,
            instructions: instructions
        )
        transcript = languageSession.transcript
        logger.info("🔄 [ChatAIManager] Language session updated with \(enabledTools.count) enabled tools")
    }
    
    // MARK: - Response Generation
    
    func generateResponse(
        for input: String,
        context: ResponseContext,
        onPartialUpdate: @escaping (String) -> Void
    ) async throws -> ChatMessage {
        logger.info("🤖 [ChatAIManager] Generating response using strategy pattern")
        
//        guard isInitialized, let session = languageSession else {
//            throw ChatError.other
//        }
        
        isProcessing = true
        streamingContent = ""
        
        defer {
            isProcessing = false
            streamingContent = nil
        }
        
        let strategy = context.recommendedStrategy
        logger.info("🎯 [ChatAIManager] Using strategy: \(type(of: strategy))")
        
        let wrappedPartialUpdate: (String) -> Void = { [weak self] content in
            self?.streamingContent = content
            onPartialUpdate(content)
        }

        do {
            let response = try await strategy.createStrategy().generateResponse(
                for: input,
                using: languageSession,
                context: context,
                onPartialUpdate: wrappedPartialUpdate
            )
            
            logger.info("✅ [ChatAIManager] Response generated successfully")
            return response
            
        } catch {
            logger.error("❌ [ChatAIManager] Response generation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    func generateStreamingResponse(for input: String, onPartialUpdate: @escaping (String) -> Void) async throws -> ChatMessage {
        let context = ResponseContext(
            input: input,
            persona: .none,
            messageCount: 0,
            settings: ChatSettings(streamingEnabled: true)
        )
        return try await generateResponse(for: input, context: context, onPartialUpdate: onPartialUpdate)
    }
    
    func generateCompleteResponse(for input: String) async throws -> ChatMessage {
        let context = ResponseContext(
            input: input,
            persona: .none,
            messageCount: 0,
            settings: ChatSettings(streamingEnabled: false)
        )
        return try await generateResponse(for: input, context: context, onPartialUpdate: { _ in })
    }
    
    func generateSessionTitle(for firstUserMessage: String) async throws -> String {
        logger.info("📝 [ChatAIManager] Generating session title")
        
        do {
            let titleResponse = try await titleGenerationSession.respond(
                to: "Generate a short, descriptive title (3-6 words) for this conversation: \(firstUserMessage)",
                generating: SessionTitle.self,
                options: GenerationOptions(temperature: 0.3)
            )
            
            let title = titleResponse.content.title
            logger.info("📋 [ChatAIManager] Generated session title: '\(title)'")
            return title
            
        } catch {
            logger.error("❌ [ChatAIManager] Failed to generate session title: \(error.localizedDescription)")
            throw ChatError.other
        }
    }
    
    // MARK: - Cleanup
    
    func reset() {
        streamingContent = nil
        isProcessing = false
        logger.info("🔄 [ChatAIManager] AI manager reset")
    }
}
