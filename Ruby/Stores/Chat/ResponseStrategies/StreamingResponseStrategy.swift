import Foundation
import FoundationModels
import Combine
import os.log

final class StreamingResponseStrategy: ObservableObject, ResponseStrategy {
    @Published var partialResponse: ChatResponse.PartiallyGenerated?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "StreamingResponseStrategy")
    
    @MainActor
    func generateResponse(
        for input: String,
        using session: LanguageModelSession,
        context: ResponseContext,
        onPartialUpdate: @escaping (String) -> Void
    ) async throws -> ChatMessage {
        logger.info("🌊 [StreamingStrategy] Starting streaming response generation")
        
        startProcessing()
        
        defer {
            completeProcessing()
        }
        
        do {
            let responseStartTime = Date()
            
            // Use plain text response for .none persona, structured for others
            if context.persona == .none {
                logger.info("🤖 [StreamingStrategy] Using plain text response for Base Model persona")
                
                let responseStream = session.streamResponse(
                    to: input,
                    options: GenerationOptions(
                        temperature: 0.7,
                        maximumResponseTokens: 1200
                    )
                )
                
                var accumulatedContent = ""
                var chunkCount = 0
                
                for try await textChunk in responseStream {
                    chunkCount += 1
                    accumulatedContent += textChunk
                    onPartialUpdate(accumulatedContent)
                    
                    if chunkCount == 1 {
                        logger.debug("📝 [StreamingStrategy] First chunk received")
                    } else if chunkCount % 10 == 0 {
                        logger.debug("📊 [StreamingStrategy] Received \(chunkCount) chunks")
                    }
                }
                
                let responseTime = Date().timeIntervalSince(responseStartTime)
                logger.info("Transcript: \(String(describing: session.transcript))")
                logger.info("🏁 [StreamingStrategy] Plain text streaming completed, total chunks: \(chunkCount)")
                logger.info("📥 [StreamingStrategy] Final response generated in \(String(format: "%.2f", responseTime))s")
                
                let chatMessage = ChatMessage(
                    content: accumulatedContent,
                    isUser: false,
                    timestamp: Date(),
                    metadata: .init(
                        processingTime: responseTime,
                        tokens: accumulatedContent.count,
                        confidence: nil
                    )
                )
                
                logger.info("✅ [StreamingStrategy] Plain text streaming response generated successfully")
                return chatMessage
                
            } else {
                logger.info("🎯 [StreamingStrategy] Using structured response for persona: \(context.persona.rawValue)")
                
                let responseStream = session.streamResponse(
                    to: input,
                    generating: ChatResponse.self,
                    includeSchemaInPrompt: true,
                    options: GenerationOptions(
                        temperature: 0.7,
                        maximumResponseTokens: 1200
                    )
                )
                
                var chunkCount = 0
                
                for try await partialChatResponse in responseStream {
                    chunkCount += 1
                    partialResponse = partialChatResponse
                    
                    // Call partial update with the current content if available
                    if let content = partialChatResponse.content {
                        onPartialUpdate(content)
                    }
                    
                    if chunkCount == 1 {
                        logger.debug("📝 [StreamingStrategy] First chunk received")
                    } else if chunkCount % 10 == 0 {
                        logger.debug("📊 [StreamingStrategy] Received \(chunkCount) chunks")
                    }
                }
                
                let responseTime = Date().timeIntervalSince(responseStartTime)
                
                guard let finalChatResponse = partialResponse?.content else {
                    throw ChatError.other
                }
                
                logger.info("Transcript: \(String(describing: session.transcript))")

                logger.info("🏁 [StreamingStrategy] Structured streaming completed, total chunks: \(chunkCount)")
                logger.info("📥 [StreamingStrategy] Final response generated in \(String(format: "%.2f", responseTime))s")
                logger.info("🎭 [StreamingStrategy] Detected tone: '\(self.partialResponse?.tone as NSObject?)'")
                logger.info("📊 [StreamingStrategy] Confidence score: \(String(format: "%.2f", self.partialResponse?.confidence ?? "N/A"))")
                
                let chatMessage = ChatMessage(
                    content: partialResponse?.content ?? "No Content",
                    isUser: false,
                    timestamp: Date(),
                    metadata: .init(
                        processingTime: responseTime,
                        tokens: nil,
                        confidence: partialResponse?.confidence
                    )
                )
                
                logger.info("✅ [StreamingStrategy] Structured streaming response generated successfully")
                return chatMessage
            }
            
        } catch let error as LanguageModelSession.GenerationError {
            logger.error("❌ [StreamingStrategy] LanguageModelSession error: \(error.localizedDescription)")
            handleGenerationError(error)
            throw mapGenerationError(error)
        } catch {
            logger.error("❌ [StreamingStrategy] Streaming failed: \(error.localizedDescription)")
            throw ChatError.other
        }
    }
    
    @MainActor
    private func startProcessing() {
        logger.debug("🔄 [StreamingStrategy] Starting processing - clearing previous state")
        isProcessing = true
        errorMessage = nil
        partialResponse = nil
    }
    
    @MainActor
    private func completeProcessing() {
        logger.debug("✅ [StreamingStrategy] Processing completed")
        isProcessing = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [StreamingStrategy] Setting error state: \(error)")
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
            logger.error("❌ [StreamingStrategy] Unhandled generation error: \(error.localizedDescription)")
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
        logger.error("❌ [StreamingStrategy] \(errorDetails)")
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
        case .unsupportedLanguageOrLocale(let context):
            return ChatError.unsupportedLanguageOrLocale(error)
        case .decodingFailure(let context):
            return ChatError.decodingFailure(error)
        case .rateLimited(let context):
            return ChatError.rateLimited(error)
        @unknown default:
            return ChatError.other
        }
    }
}
