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
            
        } catch {
            logger.error("❌ [StructuredStrategy] Structured response failed: \(error.localizedDescription)")
            setError("Structured response failed: \(error.localizedDescription)")
            throw ChatError.responseGenerationFailed
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
}
