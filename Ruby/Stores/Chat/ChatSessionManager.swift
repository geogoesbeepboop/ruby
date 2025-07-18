import Foundation
import SwiftUI
import os.log

@MainActor
@Observable
final class ChatSessionManager {
    // MARK: - Properties
    
    var currentSession: ConversationSession? = nil
    var savedSessions: [ConversationSession] = []
    
    // MARK: - Private Properties
    
    private let dataManager: DataManager
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatSessionManager")
    private var pendingSaveOperations: Set<UUID> = []
    
    // MARK: - Initialization
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        logger.info("🔧 [ChatSessionManager] Initializing ChatSessionManager")
        
        Task {
            await loadSavedSessions()
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession(with persona: AIPersona) async {
        logger.info("🆕 [ChatSessionManager] Starting new chat session")
        
        // For in-memory operation, no need to save before starting new session
        // Current session will be replaced and previous data is intentionally lost
        
        // Create new session
        let newSession = ConversationSession(
            id: UUID(),
            title: "New Conversation",
            createdAt: Date(),
            lastModified: Date(),
            messages: [defaultGreetingMessage(for: persona)],
            persona: persona
        )
        
        currentSession = newSession
        
        logger.info("✅ [ChatSessionManager] New session created with ID: \(newSession.id)")
        
        // Load saved sessions
        await loadSavedSessions()
    }
    
    func loadSession(_ session: ConversationSession) async {
        logger.info("📁 [ChatSessionManager] Loading session: \(session.id)")
        
        // For in-memory operation, no need to save when switching sessions
        // Previous session data is intentionally lost
        
        currentSession = session
        
        logger.info("✅ [ChatSessionManager] Session loaded successfully with \(session.messages.count) messages")
    }
    
    func deleteSession(_ session: ConversationSession) async {
        logger.info("🗑️ [ChatSessionManager] Deleting session: \(session.id)")
        
        do {
            try dataManager.deleteSession(withId: session.id)
            
            // Remove from saved sessions
            savedSessions.removeAll { $0.id == session.id }
            
            // If deleting current session, clear current session
            if currentSession?.id == session.id {
                currentSession = nil
            }
            
            logger.info("✅ [ChatSessionManager] Session deleted successfully")
            
        } catch {
            logger.error("❌ [ChatSessionManager] Failed to delete session: \(error.localizedDescription)")
        }
    }
    
    func updateSessionMessages(_ messages: [ChatMessage]) async {
        guard var session = currentSession else { return }
        
        session.messages = messages
        session.lastModified = Date()
        currentSession = session
        
        // For in-memory operation, no need to save on every message
        // Saves will happen when session ends or user explicitly saves
    }
    
    func updateSessionTitle(_ title: String) async {
        guard var session = currentSession else { return }
        
        session.title = title
        session.lastModified = Date()
        currentSession = session
        
        // For in-memory operation, no immediate save needed
    }
    
    func updateSessionPersona(_ persona: AIPersona) async {
        guard var session = currentSession else { return }
        
        session.persona = persona
        session.lastModified = Date()
        currentSession = session
        
        // For in-memory operation, no immediate save needed
    }
    
    // MARK: - Private Methods
    
    private func loadSavedSessions() async {
        do {
            let sessions = try dataManager.loadSessions()
            self.savedSessions = sessions
            logger.info("📂 [ChatSessionManager] Loaded \(sessions.count) saved sessions")
        } catch {
            logger.error("❌ [ChatSessionManager] Failed to load sessions: \(error.localizedDescription)")
            self.savedSessions = []
        }
    }
    
    private func saveCurrentSessionSafely() async {
        logger.debug("💭 [ChatSessionManager] Save skipped - in-memory only operation")
        // For in-memory operation, we don't save sessions to avoid blocking
        // All session data exists only in memory during app session
    }
    
    private func defaultGreetingMessage(for persona: AIPersona) -> ChatMessage {
        let greeting: String
        
        switch persona {
        case .none:
            greeting = "What's shakin, bacon?"
        case .therapist:
            greeting = "Hi there! What's on your mind today?"
        case .professor:
            greeting = "Hello! What would you like to explore and learn about today?"
        case .techLead:
            greeting = "Hey! What technical challenge can I help you tackle today?"
        case .musician:
            greeting = "Hello! Ready to dive into the world of music and creativity?"
        case .comedian:
            greeting = "Hey there! What's bringing you joy or stress today? Let's find the humor in it!"
        }
        
        return ChatMessage(
            content: greeting,
            isUser: false,
            timestamp: Date()
        )
    }
}

// MARK: - Export/Import
extension ChatSessionManager {
    
    func exportSession(_ session: ConversationSession) -> Data? {
        logger.info("📤 [ChatSessionManager] Exporting session: \(session.id)")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(session)
            logger.info("✅ [ChatSessionManager] Session exported successfully")
            return data
            
        } catch {
            logger.error("❌ [ChatSessionManager] Failed to export session: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importSession(from data: Data) async throws {
        logger.info("📥 [ChatSessionManager] Importing session from data")
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let session = try decoder.decode(ConversationSession.self, from: data)
            
            // Save imported session
            try dataManager.saveSession(session)
            
            // Add to saved sessions
            savedSessions.insert(session, at: 0)
            
            logger.info("✅ [ChatSessionManager] Session imported successfully: \(session.id)")
            
        } catch {
            logger.error("❌ [ChatSessionManager] Failed to import session: \(error.localizedDescription)")
            throw ChatError.loadFailed
        }
    }
    
    func clearAllData() async throws {
        logger.info("🗑️ [ChatSessionManager] Clearing all data")
        
        do {
            try dataManager.clearAllData()
            
            // Reset in-memory state
            savedSessions = []
            currentSession = nil
            
            logger.info("✅ [ChatSessionManager] All data cleared successfully")
            
        } catch {
            logger.error("❌ [ChatSessionManager] Failed to clear all data: \(error.localizedDescription)")
            throw ChatError.saveFailed
        }
    }
}
