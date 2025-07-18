//
//  ErrorRecoveryManager.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels
import os.log
import Combine

@MainActor
final class ErrorRecoveryManager: ObservableObject {
    @Published var isRecovering = false
    @Published var recoveryAttempts: Int = 0
    @Published var lastRecoveryAction: RecoveryAction?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ErrorRecoveryManager")
    private let maxRetryAttempts = 3
    private let baseDelaySeconds: Double = 1.0
    
    // MARK: - Recovery Actions
    
    func handleError<T>(
        _ error: Error,
        context: ErrorContext,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        logger.info("🚨 [ErrorRecovery] Handling error: \(error.localizedDescription)")
        logger.info("📍 [ErrorRecovery] Context: \(context.description)")
        
        let chatError = mapToChatError(error)
        let recoveryAction = determineRecoveryAction(for: chatError, context: context)
        
        logger.info("🔧 [ErrorRecovery] Recommended action: \(recoveryAction)")
        lastRecoveryAction = recoveryAction
        
        switch recoveryAction {
        case .retry:
            return try await retryWithBackoff(operation: operation, context: context)
        case .fallbackStrategy:
            return try await fallbackStrategy(operation: operation, context: context)
        case .degradedMode:
            return try await degradedMode(operation: operation, context: context)
        case .userIntervention:
            throw chatError // Let user handle this
        case .systemRestart:
            await systemRestart()
            return try await operation()
        }
    }
    
    // MARK: - Recovery Strategies
    
    private func retryWithBackoff<T>(
        operation: @escaping () async throws -> T,
        context: ErrorContext
    ) async throws -> T {
        logger.info("🔄 [ErrorRecovery] Starting retry with exponential backoff")
        isRecovering = true
        
        defer {
            isRecovering = false
        }
        
        for attempt in 1...maxRetryAttempts {
            do {
                recoveryAttempts = attempt
                logger.info("⏳ [ErrorRecovery] Retry attempt \(attempt)/\(self.maxRetryAttempts)")
                
                if attempt > 1 {
                    let delay = baseDelaySeconds * pow(2.0, Double(attempt - 1))
                    logger.info("⏰ [ErrorRecovery] Waiting \(delay)s before retry")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                let result = try await operation()
                logger.info("✅ [ErrorRecovery] Retry succeeded on attempt \(attempt)")
                recoveryAttempts = 0
                return result
                
            } catch {
                logger.warning("❌ [ErrorRecovery] Retry attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt == maxRetryAttempts {
                    logger.error("🚫 [ErrorRecovery] All retry attempts exhausted")
                    recoveryAttempts = 0
                    throw error
                }
            }
        }
        
        fatalError("Should never reach here")
    }
    
    private func fallbackStrategy<T>(
        operation: @escaping () async throws -> T,
        context: ErrorContext
    ) async throws -> T {
        logger.info("🔄 [ErrorRecovery] Attempting fallback strategy")
        
        // For AI operations, try with simpler parameters
        if context.type == .aiGeneration {
            return try await simplifiedAIOperation(operation: operation)
        }
        
        // For network operations, try with reduced requirements
        if context.type == .networkOperation {
            return try await reducedNetworkOperation(operation: operation)
        }
        
        // Default fallback: retry once with delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        return try await operation()
    }
    
    private func degradedMode<T>(
        operation: @escaping () async throws -> T,
        context: ErrorContext
    ) async throws -> T {
        logger.info("⚠️ [ErrorRecovery] Operating in degraded mode")
        
        // For AI operations, provide a simplified response
        if context.type == .aiGeneration {
            return try await createFallbackResponse() as! T
        }
        
        // For other operations, attempt with minimal requirements
        return try await operation()
    }
    
    private func systemRestart() async {
        logger.info("🔄 [ErrorRecovery] Performing system restart")
        
        // Reset all managers and clear caches
        // This would be coordinated with the ChatCoordinator
        recoveryAttempts = 0
        lastRecoveryAction = nil
        
        // Simulate restart delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    // MARK: - Helper Methods
    
    private func determineRecoveryAction(for error: ChatError, context: ErrorContext) -> RecoveryAction {
        switch error {
        case .networkUnavailable:
            return .retry
        case .sessionInitializationFailed:
            return .systemRestart
        case .responseGenerationFailed:
            return context.retryCount < 2 ? .retry : .fallbackStrategy
        case .contextWindowExceeded:
            return .degradedMode
        case .modelUnavailable:
            return .fallbackStrategy
        case .voiceRecognitionFailed:
            return .retry
        case .permissionDenied:
            return .userIntervention
        case .saveFailed, .loadFailed:
            return .retry
        case .assetsUnavailable:
            return .systemRestart
        case .decodingFailure:
            return .fallbackStrategy
        case .guardrailViolation:
            return .userIntervention
        case .unsupportedGuide:
            return .degradedMode
        }
    }
    
    private func mapToChatError(_ error: Error) -> ChatError {
        if let chatError = error as? ChatError {
            return chatError
        }
        
        // Map common errors to ChatError
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") {
            return .networkUnavailable
        } else if errorDescription.contains("decode") || errorDescription.contains("parsing") {
            return .decodingFailure
        } else if errorDescription.contains("permission") {
            return .permissionDenied
        } else {
            return .responseGenerationFailed
        }
    }
    
    private func simplifiedAIOperation<T>(operation: @escaping () async throws -> T) async throws -> T {
        logger.info("🔧 [ErrorRecovery] Attempting simplified AI operation")
        // This would involve reducing parameters, shorter prompts, etc.
        return try await operation()
    }
    
    private func reducedNetworkOperation<T>(operation: @escaping () async throws -> T) async throws -> T {
        logger.info("🔧 [ErrorRecovery] Attempting reduced network operation")
        // This would involve shorter timeouts, fewer resources, etc.
        return try await operation()
    }
    
    private func createFallbackResponse() async throws -> ChatMessage {
        logger.info("🔧 [ErrorRecovery] Creating fallback response")
        
        let fallbackMessages = [
            "I'm experiencing some technical difficulties. Please try rephrasing your request.",
            "I'm having trouble processing that request right now. Could you try asking something else?",
            "There seems to be a temporary issue with my response generation. Please try again in a moment.",
            "I'm currently operating in limited mode. I can still help, but my responses might be simpler."
        ]
        
        let randomMessage = fallbackMessages.randomElement() ?? fallbackMessages[0]
        
        return ChatMessage(
            content: randomMessage,
            isUser: false,
            timestamp: Date(),
            metadata: .init(
                processingTime: 0.1,
                tokens: nil,
                confidence: 0.5
            )
        )
    }
}

// MARK: - Supporting Types

enum RecoveryAction: CustomStringConvertible {
    case retry
    case fallbackStrategy
    case degradedMode
    case userIntervention
    case systemRestart
    
    var description: String {
        switch self {
        case .retry:
            return "Retry with exponential backoff"
        case .fallbackStrategy:
            return "Use fallback strategy"
        case .degradedMode:
            return "Operate in degraded mode"
        case .userIntervention:
            return "Requires user intervention"
        case .systemRestart:
            return "System restart required"
        }
    }
}

struct ErrorContext {
    let type: ErrorType
    let operation: String
    let retryCount: Int
    let timestamp: Date
    
    var description: String {
        return "\(type.rawValue) - \(operation) (retry: \(retryCount))"
    }
    
    enum ErrorType: String {
        case aiGeneration = "AI Generation"
        case networkOperation = "Network Operation"
        case fileOperation = "File Operation"
        case voiceOperation = "Voice Operation"
        case sessionManagement = "Session Management"
        case uiOperation = "UI Operation"
    }
}
