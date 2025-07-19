import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
final class ChatUIManager {
    // MARK: - Properties
    
    var currentState: ChatState = .activeChat
    var lastError: ChatError? = nil
    var settings: ChatSettings = .default
    var messages: [ChatMessage] = []
    
    // MARK: - Private Properties
    
    private let dataManager: DataManager
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatUIManager")
    
    // MARK: - Initialization
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        logger.info("🔧 [ChatUIManager] Initializing ChatUIManager")
        
        Task {
            await loadSettings()
        }
    }
    
    // MARK: - State Management
    
    func setState(_ state: ChatState) {
        currentState = state
    }
    
    func setError(_ error: ChatError) {
        lastError = error
        currentState = .error(error.localizedDescription)
        logger.error("❌ [ChatUIManager] Error set: \(error.localizedDescription)")
    }
    
    func clearError() {
        lastError = nil
        currentState = .activeChat
        logger.info("✅ [ChatUIManager] Error cleared")
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        logger.info("💬 [ChatUIManager] Adding \(message.isUser ? "user" : "AI") message")
        messages.append(message)
    }
    
    func addReaction(to messageId: UUID, reaction: String) {
        logger.info("😀 [ChatUIManager] Adding reaction '\(reaction)' to message: \(messageId)")
        
        // Find and update the message
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var message = messages[index]
            
            // Toggle reaction - remove if already exists, add if not
            if let reactionIndex = message.reactions.firstIndex(of: reaction) {
                message.reactions.remove(at: reactionIndex)
                logger.info("➖ [ChatUIManager] Removed reaction '\(reaction)'")
            } else {
                message.reactions.append(reaction)
                logger.info("➕ [ChatUIManager] Added reaction '\(reaction)'")
            }
            
            messages[index] = message
            logger.info("✅ [ChatUIManager] Reaction updated successfully")
        } else {
            logger.warning("⚠️ [ChatUIManager] Message not found for reaction: \(messageId)")
        }
    }
    
    func deleteMessage(_ message: ChatMessage) {
        logger.info("🗑️ [ChatUIManager] Deleting message: \(message.id)")
        
        messages.removeAll { $0.id == message.id }
        
        // If no messages left, we'll need to add a default greeting
        // This will be handled by the coordinator
        
        logger.info("✅ [ChatUIManager] Message deleted successfully")
    }
    
    func updateMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
        logger.info("🔄 [ChatUIManager] Messages updated, count: \(newMessages.count)")
    }
    
    func resetMessages() {
        messages = []
        logger.info("🔄 [ChatUIManager] Messages reset")
    }
    
    // MARK: - Settings Management
    
    func updatePersona(_ persona: AIPersona) {
        logger.info("👤 [ChatUIManager] Updating persona to: \(persona.rawValue)")
        settings.selectedPersona = persona
        
        Task {
            await saveSettings()
        }
    }
    
    func updateSettings(_ newSettings: ChatSettings) {
        logger.info("⚙️ [ChatUIManager] Updating settings")
        settings = newSettings
        
        Task {
            await saveSettings()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() async {
        do {
            let loadedSettings = try dataManager.loadSettings()
            self.settings = loadedSettings
            logger.info("⚙️ [ChatUIManager] Settings loaded successfully")
        } catch {
            logger.error("❌ [ChatUIManager] Failed to load settings, using defaults: \(error.localizedDescription)")
            self.settings = .default
        }
    }
    
    private func saveSettings() async {
        do {
            try dataManager.saveSettings(settings)
            logger.info("💾 [ChatUIManager] Settings saved successfully")
        } catch {
            logger.error("❌ [ChatUIManager] Failed to save settings: \(error.localizedDescription)")
            setError(.other)
        }
    }
    
    // MARK: - Utility Methods
    
    func isStateActive() -> Bool {
        switch currentState {
        case .activeChat:
            return true
        default:
            return false
        }
    }
    
    func isProcessing() -> Bool {
        switch currentState {
        case .aiThinking, .streaming:
            return true
        default:
            return false
        }
    }
    
    func hasError() -> Bool {
        if case .error = currentState {
            return true
        }
        return false
    }
}
