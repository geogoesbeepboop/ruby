//
//  ChatSearchFlow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels
import Combine
import os.log

final class ChatSearchFlow: ObservableObject {
    let session: LanguageModelSession
    @Published var currentSearch: SearchResults.PartiallyGenerated?
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatSearchFlow")
    
    init(searchTools: [Tool] = []) {
        logger.info("🚀 [ChatSearchFlow] Initializing ChatSearchFlow ObservableObject")
        
        self.session = LanguageModelSession(
            tools: searchTools,
            instructions: SearchInstructions.comprehensive
        )
        logger.info("📱 [ChatSearchFlow] LanguageModelSession initialized with search tools")
        logger.info("✅ [ChatSearchFlow] ChatSearchFlow ready for search operations")
    }
    
    @MainActor
    func handleSearchQuery(query: String) async -> ChatMessage? {
        logger.info("\n🔍 [ChatSearchFlow] === SEARCH WORKFLOW STARTED ===")
        logger.info("🔄 [ChatSearchFlow] Processing search query: '\(query)'")
        startSearching()
        
        do {
            let searchPrompt = createSearchPrompt(query: query)
            logger.info("📝 [ChatSearchFlow] Created search prompt for LanguageModelSession")
            logger.info("🤖 [ChatSearchFlow] Sending search request to Apple Foundation Models...")
            
            // PHASE 1: Execute search and synthesize results
            logger.info("🔄 [ChatSearchFlow] PHASE 1: Streaming search results and synthesis")
            let searchResultsStream = session.streamResponse(
                to: searchPrompt,
                generating: SearchResults.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.2,
                    maximumResponseTokens: 1500
                )
            )
            
            for try await partialResults in searchResultsStream {
                currentSearch = partialResults
            }
            logger.info("✅ [ChatSearchFlow] PHASE 1 COMPLETE: Search results generated")
            
            guard let completedResults = currentSearch as? SearchResults else {
                logger.error("❌ [ChatSearchFlow] Failed to obtain complete SearchResults from stream")
                setError("Search did not return complete results.")
                completeSearching()
                return nil
            }

            let searchSummary = createSearchSummary(results: completedResults)
            let chatMessage = ChatMessage(
                content: searchSummary,
                isUser: false,
                timestamp: Date(),
                metadata: .init(
                    processingTime: 0.0, // Will be updated with actual processing time
                    tokens: nil,
                    confidence: completedResults.reliability.confidence
                )
            )
            
            logger.info("✅ [ChatSearchFlow] === SEARCH WORKFLOW COMPLETED ===\n")
            completeSearching()
            return chatMessage
            
        } catch {
            logger.error("❌ [ChatSearchFlow] ERROR in search workflow: \(error.localizedDescription)")
            setError("Search failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func createSearchPrompt(query: String) -> Prompt {
        let searchPrompt = """
        Execute a comprehensive search for the following query and provide synthesized results:
        
        Query: \(query)
        
        Instructions:
        1. Search for relevant, up-to-date information
        2. Evaluate source reliability and relevance
        3. Synthesize findings into a coherent answer
        4. Provide source attribution and confidence assessment
        5. Include multiple perspectives when applicable
        """
        
        return Prompt(searchPrompt)
    }
    
    private func createSearchSummary(results: SearchResults) -> String {
        var summary = results.synthesizedAnswer
        
        if !results.results.isEmpty {
            summary += "\n\n**Sources:**\n"
            for (index, result) in results.results.enumerated() {
                summary += "\(index + 1). \(result.title) - \(result.source)\n"
            }
        }
        
        let confidencePercent = Int(results.reliability.confidence * 100)
        summary += "\n*Confidence: \(confidencePercent)% based on \(results.reliability.corroboratingSources) sources*"
        
        return summary
    }
    
    @MainActor
    private func startSearching() {
        logger.debug("🔄 [ChatSearchFlow] Setting isSearching = true, clearing previous state")
        isSearching = true
        errorMessage = nil
        currentSearch = nil
    }
    
    @MainActor
    private func completeSearching() {
        logger.debug("✅ [ChatSearchFlow] Setting isSearching = false")
        isSearching = false
    }
    
    @MainActor
    private func setError(_ error: String) {
        logger.error("❌ [ChatSearchFlow] Setting error state: \(error)")
        errorMessage = error
        isSearching = false
    }
}

// MARK: - Search Instructions

struct SearchInstructions {
    static let comprehensive = """
    You are an intelligent search assistant with access to web search tools. Your role is to:
    
    1. Execute comprehensive searches using available tools
    2. Evaluate source reliability and relevance
    3. Cross-reference information from multiple sources
    4. Synthesize findings into coherent, accurate answers
    5. Provide proper source attribution
    6. Assess confidence levels based on source quality
    
    Always prioritize accuracy, cite sources, and indicate confidence levels in your responses.
    """
}
