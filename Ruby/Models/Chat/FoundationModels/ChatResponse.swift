//
//  ChatResponse.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels

@Generable
struct ChatResponse: Equatable {
    @Guide(description: "The main response content to the user's message")
    let content: String
    @Guide(description: "The tone of the response (friendly, professional, helpful, creative, analytical)")
    let tone: String
    @Guide(description: "Confidence level in the response accuracy", .range(0.0...1.0))
    let confidence: Double
    @Guide(description: "Response category (answer, question, creative, analysis, tool_result)")
    let category: ResponseCategory
    @Guide(description: "Key topics or themes addressed in the response")
    let topics: [String]
    @Guide(description: "Whether this response requires follow-up or is complete")
    let requiresFollowUp: Bool
    
    @Generable
    enum ResponseCategory: String, CaseIterable {
        case answer, question, creative, analysis, tool_result, conversation, explanation
    }
}

@Generable
struct ConversationTurn: Equatable {
    @Guide(description: "Analysis of the user's input message")
    let userAnalysis: UserInputAnalysis
    @Guide(description: "The generated response to the user")
    let response: ChatResponse
    @Guide(description: "Processing metadata and performance metrics")
    let metadata: ConversationMetadata
    
    @Generable
    struct UserInputAnalysis: Equatable {
        @Guide(description: "Intent category of the user's message")
        let intent: UserIntent
        @Guide(description: "Complexity level of the user's request", .range(1...5))
        let complexity: Int
        @Guide(description: "Key entities or topics mentioned by the user")
        let entities: [String]
        @Guide(description: "Whether the input suggests the user wants a detailed response")
        let wantsDetailedResponse: Bool
        
        @Generable
        enum UserIntent: String, CaseIterable {
            case question, request, conversation, creative, analysis, clarification, greeting
        }
    }
    
    @Generable
    struct ConversationMetadata: Equatable {
        @Guide(description: "Processing time in seconds for this turn")
        let processingTime: Double
        @Guide(description: "Number of tools used in generating the response")
        let toolsUsed: Int
        @Guide(description: "Estimated token count for the response")
        let estimatedTokens: Int?
        @Guide(description: "Whether streaming was used for this response")
        let streamingUsed: Bool
    }
}

@Generable
struct SearchResults: Equatable {
    @Guide(description: "The search query that was processed")
    let query: String
    @Guide(description: "List of relevant search result summaries")
    let results: [SearchResult]
    @Guide(description: "Synthesized answer based on search results")
    let synthesizedAnswer: String
    @Guide(description: "Source reliability and confidence assessment")
    let reliability: SearchReliability
    
    @Generable
    struct SearchResult: Equatable {
        @Guide(description: "Title or heading of the search result")
        let title: String
        @Guide(description: "Brief summary of the content")
        let summary: String
        @Guide(description: "Source URL or identifier")
        let source: String
        @Guide(description: "Relevance score to the original query", .range(0.0...1.0))
        let relevance: Double
    }
    
    @Generable
    struct SearchReliability: Equatable {
        @Guide(description: "Overall confidence in the search results", .range(0.0...1.0))
        let confidence: Double
        @Guide(description: "Number of corroborating sources found")
        let corroboratingSources: Int
        @Guide(description: "Quality assessment of the sources")
        let sourceQuality: SourceQuality
        
        @Generable
        enum SourceQuality: String, CaseIterable {
            case high, medium, low, mixed, unknown
        }
    }
}

@Generable
struct CreativeContent: Equatable {
    @Guide(description: "The creative content generated (story, poem, code, etc.)")
    let content: String
    @Guide(description: "Type of creative content generated")
    let contentType: CreativeType
    @Guide(description: "Style or approach used in the creation")
    let style: String
    @Guide(description: "Estimated quality or completion level", .range(0.0...1.0))
    let quality: Double
    @Guide(description: "Creative constraints or requirements that were followed")
    let constraints: [String]
    @Guide(description: "Whether this is a complete work or a draft/excerpt")
    let isComplete: Bool
    
    @Generable
    enum CreativeType: String, CaseIterable {
        case story, poem, code, essay, script, song, joke, riddle, explanation
    }
}

@Generable
struct ConversationAnalysis: Equatable {
    @Guide(description: "Main topics and themes discussed in the conversation")
    let topics: [String]
    @Guide(description: "Overall sentiment of the conversation")
    let sentiment: ConversationSentiment
    @Guide(description: "Quality assessment of the conversation flow")
    let quality: ConversationQuality
    @Guide(description: "Key insights about the user's communication style")
    let userStyle: UserCommunicationStyle
    @Guide(description: "Suggested improvements or follow-up actions")
    let suggestions: [String]
    @Guide(description: "Overall conversation summary")
    let summary: String
    
    @Generable
    struct ConversationSentiment: Equatable {
        @Guide(description: "Primary emotional tone")
        let primaryTone: EmotionalTone
        @Guide(description: "Sentiment score", .range(-1.0...1.0))
        let score: Double
        @Guide(description: "Confidence in sentiment analysis", .range(0.0...1.0))
        let confidence: Double
        
        @Generable
        enum EmotionalTone: String, CaseIterable {
            case positive, negative, neutral, mixed, curious, frustrated, excited, thoughtful
        }
    }
    
    @Generable
    struct ConversationQuality: Equatable {
        @Guide(description: "Coherence and flow score", .range(0.0...1.0))
        let coherence: Double
        @Guide(description: "Engagement level", .range(0.0...1.0))
        let engagement: Double
        @Guide(description: "Information richness", .range(0.0...1.0))
        let informativeness: Double
        @Guide(description: "Overall quality rating")
        let rating: QualityRating
        
        @Generable
        enum QualityRating: String, CaseIterable {
            case excellent, good, fair, poor
        }
    }
    
    @Generable
    struct UserCommunicationStyle: Equatable {
        @Guide(description: "Typical question complexity level", .range(1...5))
        let complexityLevel: Int
        @Guide(description: "Preferred response length")
        let preferredLength: ResponseLength
        @Guide(description: "Communication formality level")
        let formalityLevel: FormalityLevel
        @Guide(description: "Interest areas and expertise")
        let interests: [String]
        
        @Generable
        enum ResponseLength: String, CaseIterable {
            case brief, moderate, detailed, comprehensive
        }
        
        @Generable
        enum FormalityLevel: String, CaseIterable {
            case casual, conversational, professional, formal
        }
    }
}