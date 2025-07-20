//
//  ChatConversationFlow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels
import Combine
import os.log

final class ChatConversationFlow: ObservableObject {
    let session: LanguageModelSession
    @Published var currentTurn: ConversationTurn.PartiallyGenerated?
    @Published var conversationAnalysis: ConversationAnalysis.PartiallyGenerated?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatConversationFlow")
    
    init(tools: [Tool] = [], instructions: String = "") {
        logger.info("🚀 [ChatConversationFlow] Initializing ChatConversationFlow ObservableObject")
        
        self.session = LanguageModelSession(
            tools: tools,
            instructions: instructions.isEmpty ? ConversationInstructions.comprehensive : instructions
        )
        logger.info("📱 [ChatConversationFlow] LanguageModelSession initialized with tools and instructions")
        logger.info("✅ [ChatConversationFlow] ChatConversationFlow ready for user interactions")
    }
    
    @MainActor
    func handleConversationTurn(input: String, conversationHistory: [ChatMessage]) async -> ChatMessage? {
        logger.info("\n💬 [ChatConversationFlow] === CONVERSATION TURN STARTED ===")
        logger.info("🔄 [ChatConversationFlow] Processing user input: '\(input)'")
        startProcessing()
        
        do {
            // Create context prompt with conversation history
            let contextPrompt = createContextualPrompt(input: input, history: conversationHistory)
            logger.info("📝 [ChatConversationFlow] Created contextual prompt for LanguageModelSession")
            logger.info("🤖 [ChatConversationFlow] Sending prompt to Apple Foundation Models...")
            
            // PHASE 1: Generate conversation turn with analysis
            logger.info("🔄 [ChatConversationFlow] PHASE 1: Streaming conversation turn analysis")
            let conversationTurnStream = session.streamResponse(
                to: contextPrompt,
                generating: ConversationTurn.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.4,
                    maximumResponseTokens: 1200
                )
            )
            
            for try await partialTurn in conversationTurnStream {
                currentTurn = partialTurn
            }
            logger.info("✅ [ChatConversationFlow] PHASE 1 COMPLETE: Conversation turn generated")
            // Create ChatMessage from the conversation turn
            let chatMessage = ChatMessage(
                content: currentTurn?.response?.content ?? "No content",
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: currentTurn?.metadata?.processingTime,
                    tokens: currentTurn?.metadata?.estimatedTokens,
                    confidence: currentTurn?.response?.confidence
                )
            )
            
            logger.info("✅ [ChatConversationFlow] === CONVERSATION TURN COMPLETED ===\n")
            completeProcessing()
            return chatMessage
            
        } catch {
            logger.error("❌ [ChatConversationFlow] ERROR in conversation workflow: \(error.localizedDescription)")
            setError("Conversation turn failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    func analyzeConversation(messages: [ChatMessage]) async {
        logger.info("\n🔍 [ChatConversationFlow] === CONVERSATION ANALYSIS STARTED ===")
        startProcessing()
        
        do {
            let analysisPrompt = createAnalysisPrompt(messages: messages)
            logger.info("📝 [ChatConversationFlow] Created analysis prompt for conversation insights")
            
            // PHASE 2: Analyze overall conversation patterns
            logger.info("🔄 [ChatConversationFlow] PHASE 2: Streaming conversation analysis")
            let analysisStream = session.streamResponse(
                to: analysisPrompt,
                generating: ConversationAnalysis.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.2,
                    maximumResponseTokens: 800
                )
            )
            
            for try await partialAnalysis in analysisStream {
                conversationAnalysis = partialAnalysis
            }
            logger.info("✅ [ChatConversationFlow] PHASE 2 COMPLETE: Conversation analysis generated")
            
        } catch {
            logger.error("❌ [ChatConversationFlow] ERROR in analysis workflow: \(error.localizedDescription)")
            setError("Conversation analysis failed: \(error.localizedDescription)")
        }
        
        logger.info("✅ [ChatConversationFlow] === CONVERSATION ANALYSIS COMPLETED ===\n")
        completeProcessing()
    }
    
    // MARK: - Private Methods
    
    private func createContextualPrompt(input: String, history: [ChatMessage]) -> Prompt {
        let recentHistory = history.suffix(5) // Last 5 messages for context
        let historyContext = recentHistory.map { message in
            "\(message.isUser ? "User" : "Assistant"): \(message.content)"
        }.joined(separator: "\n")
        
        let fullPrompt = """
        Conversation Context:
        \(historyContext)
        
        Current User Input: \(input)
        
        Generate a comprehensive conversation turn analysis including user intent analysis and an appropriate response.
        """
        
        return Prompt(fullPrompt)
    }
    
    private func createAnalysisPrompt(messages: [ChatMessage]) -> Prompt {
        let conversationText = messages.map { message in
            "\(message.isUser ? "User" : "Assistant"): \(message.content)"
        }.joined(separator: "\n")
        
        let analysisPrompt = """
        Analyze this conversation for patterns, themes, and insights:
        
        \(conversationText)
        
        Provide a comprehensive analysis including topics, sentiment, and conversation quality.
        """
        
        return Prompt(analysisPrompt)
    }
    
    @MainActor
    private func startProcessing() {
        logger.debug("🔄 [ChatConversationFlow] Setting isProcessing = true, clearing previous state")
        isProcessing = true
        errorMessage = nil
    }
    
    @MainActor
    private func completeProcessing() {
        logger.debug("✅ [ChatConversationFlow] Setting isProcessing = false")
        isProcessing = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [ChatConversationFlow] Setting error state: \(error)")
        errorMessage = error
        isProcessing = false
    }
}

// MARK: - Conversation Instructions

struct ConversationInstructions {
    static let comprehensive = """
    You are an intelligent conversation assistant. Your role is to:
    
    1. Analyze user input for intent, complexity, and context
    2. Generate thoughtful, contextually appropriate responses
    3. Maintain conversation flow and coherence
    4. Provide helpful, accurate, and engaging responses
    5. Adapt your tone and style to match the conversation context
    
    Always be helpful, respectful, and aim to provide value in every interaction.
    """
}
