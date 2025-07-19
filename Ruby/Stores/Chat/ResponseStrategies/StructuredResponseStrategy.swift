import Foundation
import FoundationModels
import Combine
import os.log

final class StructuredResponseStrategy: ObservableObject, ResponseStrategy {
    @Published var partialResponse: ConversationTurn.PartiallyGenerated?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "StructuredResponseStrategy")
    
    @MainActor
    func generateResponse(
        for input: String,
        using session: LanguageModelSession,
        onPartialUpdate: @escaping (String) -> Void
    ) async throws -> ChatMessage {
        logger.info("🎯 [StructuredStrategy] Starting structured response generation with multi-phase streaming")
        
        startProcessing()
        
        defer {
            completeProcessing()
        }
        
        do {
            let responseStartTime = Date()
            
            // Use ConversationTurn for more comprehensive structured analysis
            logger.info("🔄 [StructuredStrategy] PHASE 1: Streaming conversation turn analysis")
            let conversationTurnStream = session.streamResponse(
                to: input,
                generating: ConversationTurn.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.2,
                    maximumResponseTokens: 1000
                )
            )
            
            for try await partialConversationTurn in conversationTurnStream {
                partialResponse = partialConversationTurn
                
                // Call partial update with the current response content if available
                if let responseContent = partialConversationTurn.response?.content {
                    onPartialUpdate(responseContent)
                }
            }
            
            let responseTime = Date().timeIntervalSince(responseStartTime)
            
            logger.info("📥 [StructuredStrategy] Structured conversation turn generated in \(String(format: "%.2f", responseTime))s")
            logger.info("🎭 [StructuredStrategy] User intent: '\(self.partialResponse?.userAnalysis?.intent?.rawValue as NSObject?)'")
            logger.info("📊 [StructuredStrategy] Input complexity: \(self.partialResponse?.userAnalysis?.complexity as NSObject?)/5")
            logger.info("🎭 [StructuredStrategy] Response tone: '\(self.partialResponse?.response?.tone as NSObject?)'")
            logger.info("📊 [StructuredStrategy] Response confidence: \(String(format: "%.2f", self.partialResponse?.response?.confidence ?? "N/A"))")
            
            let chatMessage = ChatMessage(
                content: partialResponse?.response?.content ?? "No Content",
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: responseTime,
                    tokens: partialResponse?.metadata?.estimatedTokens,
                    confidence: partialResponse?.response?.confidence
                )
            )
            
            logger.info("✅ [StructuredStrategy] Structured response generated successfully")
            return chatMessage
            
        } catch let error as LanguageModelSession.GenerationError {
            logger.error("❌ [StructuredStrategy] LanguageModelSession error: \(error.localizedDescription)")
            handleGenerationError(error)
            throw mapGenerationError(error)
        } catch {
            logger.error("❌ [StructuredStrategy] Structured response failed: \(error.localizedDescription)")
            throw ChatError.other
        }
    }
    
    @MainActor
    private func startProcessing() {
        logger.debug("🔄 [StructuredStrategy] Starting processing - clearing previous state")
        isProcessing = true
        errorMessage = nil
        partialResponse = nil
    }
    
    @MainActor
    private func completeProcessing() {
        logger.debug("✅ [StructuredStrategy] Processing completed")
        isProcessing = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [StructuredStrategy] Setting error state: \(error)")
        errorMessage = error
        isProcessing = false
    }
    
    private func handleGenerationError(_ error: LanguageModelSession.GenerationError) {
        switch error {
        case .exceededContextWindowSize(let context):
            presentGenerationError(error, context: context)
            
        case .assetsUnavailable(let context):
            presentGenerationError(error, context: context)
     
        case .guardrailViolation(let context):
            presentGenerationError(error, context: context)
     
        case .unsupportedGuide(let context):
            presentGenerationError(error, context: context)
     
        case .unsupportedLanguageOrLocale(let context):
            presentGenerationError(error, context: context)
            
        case .decodingFailure(let context):
            presentGenerationError(error, context: context)
            
        case .rateLimited(let context):
            presentGenerationError(error, context: context)
            
        default:
            logger.error("❌ [StructuredStrategy] Unhandled generation error: \(error.localizedDescription)")
        }
    }
     
    private func presentGenerationError(_ error: LanguageModelSession.GenerationError,
                                       context: LanguageModelSession.GenerationError.Context) {
        let errorDetails = """
            Failed to respond: \(error.localizedDescription).
            Failure reason: \(String(describing: error.failureReason)).
            Recovery suggestion: \(String(describing: error.recoverySuggestion)).
            Context: \(String(describing: context))
            """
        logger.error("❌ [StructuredStrategy] \(errorDetails)")
    }
    
    private func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> ChatError {
        switch error {
        case .exceededContextWindowSize(let context):
            return ChatError.exceededContextWindowSize(error)
        case .assetsUnavailable(let context):
            return ChatError.assetsUnavailable(error)
        case .guardrailViolation(let context):
            return ChatError.guardrailViolation(error)
        case .unsupportedGuide(let context):
            return ChatError.unsupportedGuide(error)
        case .decodingFailure(let context):
            return ChatError.decodingFailure(error)
        case .unsupportedLanguageOrLocale(let context):
            return ChatError.unsupportedLanguageOrLocale(error)
        case .rateLimited(let context):
            return ChatError.rateLimited(error)
        @unknown default:
            return ChatError.other
        }
    }
}
