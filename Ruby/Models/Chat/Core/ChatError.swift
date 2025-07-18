//
//  ChatError.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation 

enum ChatError: LocalizedError {
    case sessionInitializationFailed
    case contextWindowExceeded
    case modelUnavailable
    case voiceRecognitionFailed
    case networkUnavailable
    case permissionDenied
    case saveFailed
    case loadFailed
    case responseGenerationFailed
    
    // New LanguageModelSession.GenerationError specific cases
    case assetsUnavailable
    case decodingFailure
    case guardrailViolation
    case unsupportedGuide
    
    var errorDescription: String? {
        switch self {
        case .sessionInitializationFailed:
            return "Failed to initialize AI session"
        case .contextWindowExceeded:
            return "Conversation too long, starting new session"
        case .modelUnavailable:
            return "AI model temporarily unavailable"
        case .voiceRecognitionFailed:
            return "Voice recognition failed"
        case .networkUnavailable:
            return "Network connection required for some features"
        case .permissionDenied:
            return "Permission required for this feature"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .responseGenerationFailed:
            return "Failed to generate AI response"
        case .assetsUnavailable:
            return "Required AI assets are currently unavailable"
        case .decodingFailure:
            return "Failed to process AI response format"
        case .guardrailViolation:
            return "Content detected likely to be unsafe"
        case .unsupportedGuide:
            return "Unsupported response format requested"
        }
    }
    
    var isUserFacingError: Bool {
        switch self {
        case .guardrailViolation, .contextWindowExceeded:
            return true
        default:
            return false
        }
    }
}
