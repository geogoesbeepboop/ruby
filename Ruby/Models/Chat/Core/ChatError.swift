//
//  ChatError.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation 
import FoundationModels

enum ChatError: LocalizedError {
    case exceededContextWindowSize(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case assetsUnavailable(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case guardrailViolation(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case unsupportedGuide(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case unsupportedLanguageOrLocale(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case decodingFailure(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case rateLimited(_ error: LanguageModelSession.GenerationError, _ context: LanguageModelSession.GenerationError.Context? = nil)
    case other
    
    var errorDescription: String? {
        switch self {
        case .exceededContextWindowSize(let context, let error):
            return """
                Failed to respond: Context window size exceeded.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).
                """
        case .assetsUnavailable(let context, let error):
            return """
                Failed to respond: Required AI assets are currently unavailable.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).
                """
        case .guardrailViolation(let context, let error):
            return """
                Failed to respond: Content detected likely to be unsafe.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).

                """
        case .unsupportedGuide(let context, let error):
            return """
                Failed to respond: Unsupported response format requested.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).
                """
        case .unsupportedLanguageOrLocale(let context, let error):
            return """
                Failed to respond: Language or locale not supported.
                Failure context: \(String(describing: context)).
                """
        case .decodingFailure(let context, let error):
            return """
                Failed to respond: Failed to process AI response format.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).
                """
        case .rateLimited(let context, let error):
            return """
                Failed to respond: Too many requests, please try again later.
                Failure context: \(String(describing: context)).
                Failure error: \(String(describing: error)).
                """
        case .other:
            return "An unknown error occurred."
        }
    }
    
    var isUserFacingError: Bool {
        switch self {
        case .guardrailViolation, .exceededContextWindowSize, .rateLimited:
            return true
        default:
            return false
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .exceededContextWindowSize:
            return "Try starting a new conversation or shortening your message."
        case .guardrailViolation:
            return "Please rephrase your request to avoid potentially harmful content."
        case .assetsUnavailable:
            return "Please try again in a few moments. The AI model may be temporarily unavailable."
        case .decodingFailure:
            return "Please try rephrasing your request or start a new conversation."
        case .unsupportedGuide:
            return "Try simplifying your request or asking in a different way."
        case .rateLimited:
            return "Please wait a moment before sending another message."
        case .unsupportedLanguageOrLocale:
            return "Please try using a supported language or locale."
        case .other:
            return "Unknown error, Please try again later."
        }
    }
}
