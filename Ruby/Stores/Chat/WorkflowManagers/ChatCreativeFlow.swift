//
//  ChatCreativeFlow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels
import Combine
import os.log

final class ChatCreativeFlow: ObservableObject {
    let session: LanguageModelSession
    @Published var currentCreation: CreativeContent.PartiallyGenerated?
    @Published var isCreating = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatCreativeFlow")
    
    init() {
        logger.info("🚀 [ChatCreativeFlow] Initializing ChatCreativeFlow ObservableObject")
        
        self.session = LanguageModelSession(
            tools: [], // Creative work typically doesn't need external tools
            instructions: CreativeInstructions.comprehensive
        )
        logger.info("📱 [ChatCreativeFlow] LanguageModelSession initialized for creative work")
        logger.info("✅ [ChatCreativeFlow] ChatCreativeFlow ready for creative tasks")
    }
    
    @MainActor
    func handleCreativeRequest(prompt: String, contentType: CreativeContent.CreativeType? = nil) async -> ChatMessage? {
        logger.info("\n🎨 [ChatCreativeFlow] === CREATIVE WORKFLOW STARTED ===")
        logger.info("🔄 [ChatCreativeFlow] Processing creative request: '\(prompt)'")
        startCreating()
        
        do {
            let creativePrompt = createCreativePrompt(request: prompt, type: contentType)
            logger.info("📝 [ChatCreativeFlow] Created creative prompt for LanguageModelSession")
            logger.info("🤖 [ChatCreativeFlow] Sending creative request to Apple Foundation Models...")
            
            // PHASE 1: Generate creative content with metadata
            logger.info("🔄 [ChatCreativeFlow] PHASE 1: Streaming creative content generation")
            let creativeContentStream = session.streamResponse(
                to: creativePrompt,
                generating: CreativeContent.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.8, // Higher temperature for creativity
                    maximumResponseTokens: 2000
                )
            )
            
            for try await partialContent in creativeContentStream {
                currentCreation = partialContent
            }
            logger.info("✅ [ChatCreativeFlow] PHASE 1 COMPLETE: Creative content generated")

            guard let finalContent = currentCreation as? CreativeContent else {
                return nil
            }
            
            // Create ChatMessage from creative content
            let formattedContent = formatCreativeContent(content: finalContent)
            let chatMessage = ChatMessage(
                content: formattedContent,
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: 0.0, // Will be updated with actual processing time
                    tokens: nil,
                    confidence: finalContent.quality
                )
            )
            
            logger.info("🎭 [ChatCreativeFlow] Created \(finalContent.contentType.rawValue): quality \(String(format: "%.2f", finalContent.quality))")
            logger.info("✅ [ChatCreativeFlow] === CREATIVE WORKFLOW COMPLETED ===\n")
            completeCreating()
            return chatMessage
            
        } catch {
            logger.error("❌ [ChatCreativeFlow] ERROR in creative workflow: \(error.localizedDescription)")
            setError("Creative task failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    func generateMultiPhaseCreative(request: String) async -> [ChatMessage] {
        logger.info("\n🎨 [ChatCreativeFlow] === MULTI-PHASE CREATIVE WORKFLOW STARTED ===")
        var messages: [ChatMessage] = []
        
        do {
            // PHASE 1: Generate initial creative content
            if let initialMessage = await handleCreativeRequest(prompt: request) {
                messages.append(initialMessage)
            }
            
            // PHASE 2: Generate refinements or variations
            if let content = currentCreation?.content {
                let refinementPrompt = """
                Based on the creative work you just generated:
                \(content)
                
                Create a refined or alternative version that explores different aspects or improves upon the original.
                """
                
                if let refinementMessage = await handleCreativeRequest(prompt: refinementPrompt) {
                    messages.append(refinementMessage)
                }
            }
            
        } catch {
            logger.error("❌ [ChatCreativeFlow] Multi-phase creative workflow failed: \(error.localizedDescription)")
        }
        
        logger.info("✅ [ChatCreativeFlow] === MULTI-PHASE CREATIVE WORKFLOW COMPLETED ===\n")
        return messages
    }
    
    // MARK: - Private Methods
    
    private func createCreativePrompt(request: String, type: CreativeContent.CreativeType?) -> Prompt {
        var prompt = "Create original, engaging content based on this request:\n\n\(request)\n\n"
        
        if let specificType = type {
            prompt += "Content type: \(specificType.rawValue)\n"
        }
        
        prompt += """
        Instructions:
        1. Be creative, original, and engaging
        2. Follow any specific constraints or requirements mentioned
        3. Ensure the content is appropriate and high-quality
        4. Include relevant style and formatting
        5. Assess the quality and completeness of your creation
        """
        
        return Prompt(prompt)
    }
    
    private func formatCreativeContent(content: CreativeContent) -> String {
        var formatted = content.content
        
        // Add metadata footer for context
        formatted += "\n\n---\n"
        formatted += "*\(content.contentType.rawValue.capitalized)* | "
        formatted += "Style: \(content.style) | "
        formatted += "Quality: \(String(format: "%.0f", content.quality * 100))%"
        
        if !content.constraints.isEmpty {
            formatted += "\nConstraints followed: \(content.constraints.joined(separator: ", "))"
        }
        
        return formatted
    }
    
    @MainActor
    private func startCreating() {
        logger.debug("🔄 [ChatCreativeFlow] Setting isCreating = true, clearing previous state")
        isCreating = true
        errorMessage = nil
        currentCreation = nil
    }
    
    @MainActor
    private func completeCreating() {
        logger.debug("✅ [ChatCreativeFlow] Setting isCreating = false")
        isCreating = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [ChatCreativeFlow] Setting error state: \(error)")
        errorMessage = error
        isCreating = false
    }
}

// MARK: - Creative Instructions

struct CreativeInstructions {
    static let comprehensive = """
    You are a creative AI assistant specializing in generating original content. Your role is to:
    
    1. Create engaging, original content across various formats
    2. Adapt style and tone to match the requested content type
    3. Follow creative constraints while maintaining quality
    4. Provide rich, detailed content that engages the audience
    5. Assess and improve the quality of your creations
    6. Be imaginative while remaining appropriate and helpful
    
    Always strive for originality, creativity, and quality in every piece you create.
    """
}
