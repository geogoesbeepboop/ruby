import Foundation
import FoundationModels
import Combine

// MARK: - Response Strategy Protocol

protocol ResponseStrategy: ObservableObject {
    func generateResponse(
        for input: String,
        using session: LanguageModelSession,
        context: ResponseContext,
        onPartialUpdate: @escaping (String) -> Void
    ) async throws -> ChatMessage
}

// MARK: - Response Strategy Types

enum ResponseStrategyType {
    case streaming
    case complete
    case structured
    
    func createStrategy() -> any ResponseStrategy {
        switch self {
        case .streaming:
            return StreamingResponseStrategy()
        case .complete:
            return CompleteResponseStrategy()
        case .structured:
            return StructuredResponseStrategy()
        }
    }
}

// MARK: - Response Context

struct ResponseContext {
    let input: String
    let persona: AIPersona
    let messageCount: Int
    let settings: ChatSettings    
    var shouldUseStreaming: Bool {
        return settings.streamingEnabled && input.count > 50
    }
    
    var shouldUseStructured: Bool {
        // Use structured responses for complex queries
        return input.lowercased().contains("analyze") ||
               input.lowercased().contains("compare") ||
               input.lowercased().contains("explain") ||
               input.lowercased().contains("summarize")
    }
    
    var recommendedStrategy: ResponseStrategyType {
        if shouldUseStructured {
            return .structured
        } else if shouldUseStreaming {
            return .streaming
        } else {
            return .complete
        }
    }
}
