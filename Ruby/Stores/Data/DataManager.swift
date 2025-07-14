import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class DataManager {
    private var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    static let shared = DataManager()
    
    private init() {
        do {
            let schema = Schema([
                PersistedChatSession.self,
                PersistedChatMessage.self,
                PersistedChatSettings.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic // Enable CloudKit sync
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            container.mainContext.autosaveEnabled = true

            self.modelContainer = container
            self.modelContext = container.mainContext
        } catch {
            fatalError("Failed to initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: ConversationSession) throws {
        // Check if session already exists
        let predicate = #Predicate<PersistedChatSession> { $0.id == session.id }
        let descriptor = FetchDescriptor<PersistedChatSession>(predicate: predicate)
        
        if let existingSession = try modelContext.fetch(descriptor).first {
            // Update existing session
            existingSession.title = session.title
            existingSession.lastModified = session.lastModified
            existingSession.persona = session.persona.rawValue
            
            // Update messages (replace all for simplicity)
            existingSession.messages.removeAll()
            for message in session.messages {
                let persistedMessage = message.toPersistedMessage()
                persistedMessage.session = existingSession
                existingSession.messages.append(persistedMessage)
                modelContext.insert(persistedMessage)
            }
        } else {
            // Create new session
            let persistedSession = session.toPersistedSession()
            modelContext.insert(persistedSession)
            
            // Insert all messages
            for message in persistedSession.messages {
                modelContext.insert(message)
            }
        }
        
        try modelContext.save()
    }
    
    func loadSessions() throws -> [ConversationSession] {
        let descriptor = FetchDescriptor<PersistedChatSession>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        
        let persistedSessions = try modelContext.fetch(descriptor)
        return persistedSessions.map { $0.toConversationSession() }
    }
    
    func deleteSession(withId id: UUID) throws {
        let predicate = #Predicate<PersistedChatSession> { $0.id == id }
        let descriptor = FetchDescriptor<PersistedChatSession>(predicate: predicate)
        
        if let session = try modelContext.fetch(descriptor).first {
            modelContext.delete(session)
            try modelContext.save()
        }
    }
    
    func loadSession(withId id: UUID) throws -> ConversationSession? {
        let predicate = #Predicate<PersistedChatSession> { $0.id == id }
        let descriptor = FetchDescriptor<PersistedChatSession>(predicate: predicate)
        
        return try modelContext.fetch(descriptor).first?.toConversationSession()
    }
    
    // MARK: - Settings Management
    
    func saveSettings(_ settings: ChatSettings) throws {
        let predicate = #Predicate<PersistedChatSettings> { $0.id == "default" }
        let descriptor = FetchDescriptor<PersistedChatSettings>(predicate: predicate)
        
        if let existingSettings = try modelContext.fetch(descriptor).first {
            existingSettings.update(from: settings)
        } else {
            let persistedSettings = settings.toPersistedSettings()
            modelContext.insert(persistedSettings)
        }
        
        try modelContext.save()
    }
    
    func loadSettings() throws -> ChatSettings {
        let predicate = #Predicate<PersistedChatSettings> { $0.id == "default" }
        let descriptor = FetchDescriptor<PersistedChatSettings>(predicate: predicate)
        
        if let persistedSettings = try modelContext.fetch(descriptor).first {
            return persistedSettings.toChatSettings()
        } else {
            // Return default settings if none exist
            return ChatSettings.default
        }
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage, to sessionId: UUID) throws {
        let predicate = #Predicate<PersistedChatSession> { $0.id == sessionId }
        let descriptor = FetchDescriptor<PersistedChatSession>(predicate: predicate)
        
        guard let session = try modelContext.fetch(descriptor).first else {
            throw DataError.sessionNotFound
        }
        
        let persistedMessage = message.toPersistedMessage()
        persistedMessage.session = session
        session.messages.append(persistedMessage)
        session.lastModified = Date()
        
        modelContext.insert(persistedMessage)
        try modelContext.save()
    }
    
    func deleteMessage(withId messageId: UUID) throws {
        let predicate = #Predicate<PersistedChatMessage> { $0.id == messageId }
        let descriptor = FetchDescriptor<PersistedChatMessage>(predicate: predicate)
        
        if let message = try modelContext.fetch(descriptor).first {
            message.session?.lastModified = Date()
            modelContext.delete(message)
            try modelContext.save()
        }
    }
    
    // MARK: - Analytics and Cleanup
    
    func getSessionCount() throws -> Int {
        let descriptor = FetchDescriptor<PersistedChatSession>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func getTotalMessageCount() throws -> Int {
        let descriptor = FetchDescriptor<PersistedChatMessage>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func cleanupOldSessions(olderThan days: Int = 30) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = #Predicate<PersistedChatSession> { $0.lastModified < cutoffDate }
        let descriptor = FetchDescriptor<PersistedChatSession>(predicate: predicate)
        
        let oldSessions = try modelContext.fetch(descriptor)
        for session in oldSessions {
            modelContext.delete(session)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Export/Import
    
    func exportAllData() throws -> Data {
        let sessions = try loadSessions()
        let settings = try loadSettings()
        
        let exportData = ExportData(sessions: sessions, settings: settings)
        return try JSONEncoder().encode(exportData)
    }
    
    func importData(_ data: Data) throws {
        let exportData = try JSONDecoder().decode(ExportData.self, from: data)
        
        // Clear existing data
        try deleteAllSessions()
        
        // Import sessions
        for session in exportData.sessions {
            try saveSession(session)
        }
        
        // Import settings
        try saveSettings(exportData.settings)
    }
    
    func deleteAllSessions() throws {
        let descriptor = FetchDescriptor<PersistedChatSession>()
        let sessions = try modelContext.fetch(descriptor)
        
        for session in sessions {
            modelContext.delete(session)
        }
        
        try modelContext.save()
    }
    
    func clearAllData() throws {
        try deleteAllSessions()
        
        // Also clear settings and reset to defaults
        let predicate = #Predicate<PersistedChatSettings> { $0.id == "default" }
        let descriptor = FetchDescriptor<PersistedChatSettings>(predicate: predicate)
        
        if let settings = try modelContext.fetch(descriptor).first {
            modelContext.delete(settings)
        }
        
        try modelContext.save()
    }
    
    // MARK: - ModelContainer Access
    
    var container: ModelContainer {
        modelContainer
    }
}

// MARK: - Supporting Types

enum DataError: LocalizedError {
    case sessionNotFound
    case messageNotFound
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Chat session not found"
        case .messageNotFound:
            return "Message not found"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        }
    }
}

private struct ExportData: Codable {
    let sessions: [ConversationSession]
    let settings: ChatSettings
    let exportDate: Date = Date()
}
