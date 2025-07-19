import Foundation
import FoundationModels
import Combine
import os.log

final class CompleteResponseStrategy: ObservableObject, ResponseStrategy {
    @Published var partialResponse: ChatResponse.PartiallyGenerated?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "CompleteResponseStrategy")
    
    @MainActor
    func generateResponse(
        for input: String,
        using session: LanguageModelSession,
        onPartialUpdate: @escaping (String) -> Void
    ) async throws -> ChatMessage {
        logger.info("📄 [CompleteStrategy] Starting complete response generation with streaming")
        logger.info("🔤 [CompleteStrategy] Input: '\(input)'")
        
        startProcessing()
        
        defer {
            completeProcessing()
        }
        
        do {
            let responseStartTime = Date()
            
            // Use streamResponse even for "complete" strategy to maintain consistency
            logger.info("🌊 [CompleteStrategy] Using streamResponse for consistent streaming behavior")
            
            // For now, use input directly - conversation history context is handled by LanguageModelSession
            
            let responseStream = session.streamResponse(
                to: input,
                generating: ChatResponse.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.7,  // Increased for more natural responses
                    maximumResponseTokens: 1200  // Increased for longer responses
                )
            )
            
            var finalResponse: ChatResponse?
            
            for try await partialChatResponse in responseStream {
                partialResponse = partialChatResponse
                
                // Call partial update with the current content if available
                if let content = partialChatResponse.content {
                    onPartialUpdate(content)
                }
            }
            
            let responseTime = Date().timeIntervalSince(responseStartTime)
            logger.info("📥 [CompleteStrategy] Structured response generated in \(String(format: "%.2f", responseTime))s")
            logger.info("🎭 [CompleteStrategy] Detected tone: '\(self.partialResponse?.tone as NSObject?)'")
            logger.info("📊 [CompleteStrategy] Confidence score: \(String(format: "%.2f", self.partialResponse?.confidence ?? "N/A"))")
            
            let chatMessage = ChatMessage(
                content: partialResponse?.content ?? "No Content",
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: responseTime,
                    tokens: partialResponse?.content?.count, // Approximate token count
                    confidence: partialResponse?.confidence,
                    tone: partialResponse?.tone,
                    category: partialResponse?.category?.rawValue,
                    topics: partialResponse?.topics,
                    requiresFollowUp: partialResponse?.requiresFollowUp
                )
            )
            
            logger.info("✅ [CompleteStrategy] Complete response generated successfully")
            return chatMessage
            
        } catch let error as LanguageModelSession.GenerationError {
            logger.error("❌ [CompleteStrategy] LanguageModelSession error: \(error.localizedDescription)")
            handleGenerationError(error)
            throw mapGenerationError(error)
        } catch {
            logger.error("❌ [CompleteStrategy] Complete response failed: \(error.localizedDescription)")
            setError("Complete response failed: \(error.localizedDescription)")
            let chatMessage = ChatMessage(
                content: "Unknown error",
                isUser: false,
                timestamp: Date()
            )
            return chatMessage
        }
    }
    
    @MainActor
    private func startProcessing() {
        logger.debug("🔄 [CompleteStrategy] Starting processing - clearing previous state")
        isProcessing = true
        errorMessage = nil
        partialResponse = nil
    }
    
    @MainActor
    private func completeProcessing() {
        logger.debug("✅ [CompleteStrategy] Processing completed")
        isProcessing = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [CompleteStrategy] Setting error state: \(error)")
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
            logger.error("❌ [CompleteStrategy] Unhandled generation error: \(error.localizedDescription)")
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
        logger.error("❌ [CompleteStrategy] \(errorDetails)")
        setError(error.localizedDescription)
    }
    
    private func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> ChatError {
        switch error {
        case .exceededContextWindowSize:
            return ChatError.exceededContextWindowSize(error)
        case .assetsUnavailable:
            return ChatError.assetsUnavailable(error)
        case .guardrailViolation:
            return ChatError.guardrailViolation(error)
        case .unsupportedGuide:
            return ChatError.unsupportedGuide(error)
        case .unsupportedLanguageOrLocale :
            return ChatError.unsupportedLanguageOrLocale(error)
        case .decodingFailure :
            return ChatError.decodingFailure(error)
        case .rateLimited :
            return ChatError.rateLimited(error)
        default:
            return ChatError.other
        }
    }
}
