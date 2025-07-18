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
        
        startProcessing()
        
        defer {
            completeProcessing()
        }
        
        do {
            let responseStartTime = Date()
            
            // Use streamResponse even for "complete" strategy to maintain consistency
            logger.info("🌊 [CompleteStrategy] Using streamResponse for consistent streaming behavior")
            let responseStream = session.streamResponse(
                to: input,
                generating: ChatResponse.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.3,
                    maximumResponseTokens: 800
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
                    tokens: nil,
                    confidence: partialResponse?.confidence
                )
            )
            
            logger.info("✅ [CompleteStrategy] Complete response generated successfully")
            return chatMessage
            
        } catch {
            logger.error("❌ [CompleteStrategy] Complete response failed: \(error.localizedDescription)")
            setError("Complete response failed: \(error.localizedDescription)")
            throw ChatError.responseGenerationFailed
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
}
