import Foundation
import SwiftData

// MARK: - SwiftData Models for Chat Persistence

@Model
final class PersistedChatSession {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var lastModified: Date
    var persona: String // AIPersona.rawValue
    
    @Relationship(deleteRule: .cascade) var messages: [PersistedChatMessage] = []
    
    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        persona: String
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.persona = persona
    }
    
    // Convert to domain model
    func toConversationSession() -> ConversationSession {
        ConversationSession(
            id: id,
            title: title,
            createdAt: createdAt,
            lastModified: lastModified,
            messages: messages.map { $0.toChatMessage() },
            persona: AIPersona(rawValue: persona) ?? .friendly
        )
    }
}

@Model
final class PersistedChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var reactions: [String] = []
    
    // Metadata
    var processingTime: TimeInterval?
    var tokens: Int?
    var confidence: Double?
    
    @Relationship(inverse: \PersistedChatSession.messages) var session: PersistedChatSession?
    
    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        reactions: [String] = [],
        processingTime: TimeInterval? = nil,
        tokens: Int? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.reactions = reactions
        self.processingTime = processingTime
        self.tokens = tokens
        self.confidence = confidence
    }
    
    // Convert to domain model
    func toChatMessage() -> ChatMessage {
        var message = ChatMessage(
            content: content,
            isUser: isUser,
            timestamp: timestamp
        )
        message.reactions = reactions
        message.metadata = ChatMessage.MessageMetadata(
            processingTime: processingTime,
            tokens: tokens,
            confidence: confidence
        )
        return message
    }
}

@Model
final class PersistedChatSettings {
    @Attribute(.unique) var id: String = "default"
    var selectedPersona: String
    var voiceEnabled: Bool
    var streamingEnabled: Bool
    var maxContextLength: Int
    var autoSaveConversations: Bool
    var lastModified: Date
    
    init(
        selectedPersona: String = AIPersona.friendly.rawValue,
        voiceEnabled: Bool = true,
        streamingEnabled: Bool = true,
        maxContextLength: Int = 8000,
        autoSaveConversations: Bool = true
    ) {
        self.selectedPersona = selectedPersona
        self.voiceEnabled = voiceEnabled
        self.streamingEnabled = streamingEnabled
        self.maxContextLength = maxContextLength
        self.autoSaveConversations = autoSaveConversations
        self.lastModified = Date()
    }
    
    // Convert to domain model
    func toChatSettings() -> ChatSettings {
        ChatSettings(
            selectedPersona: AIPersona(rawValue: selectedPersona) ?? .friendly,
            voiceEnabled: voiceEnabled,
            streamingEnabled: streamingEnabled,
            maxContextLength: maxContextLength,
            autoSaveConversations: autoSaveConversations
        )
    }
    
    // Update from domain model
    func update(from settings: ChatSettings) {
        selectedPersona = settings.selectedPersona.rawValue
        voiceEnabled = settings.voiceEnabled
        streamingEnabled = settings.streamingEnabled
        maxContextLength = settings.maxContextLength
        autoSaveConversations = settings.autoSaveConversations
        lastModified = Date()
    }
}

// MARK: - Domain Model Extensions

extension ConversationSession {
    func toPersistedSession() -> PersistedChatSession {
        let persistedSession = PersistedChatSession(
            id: id,
            title: title,
            createdAt: createdAt,
            lastModified: lastModified,
            persona: persona.rawValue
        )
        
        persistedSession.messages = messages.map { message in
            let persistedMessage = PersistedChatMessage(
                id: message.id,
                content: message.content,
                isUser: message.isUser,
                timestamp: message.timestamp,
                reactions: message.reactions,
                processingTime: message.metadata?.processingTime,
                tokens: message.metadata?.tokens,
                confidence: message.metadata?.confidence
            )
            persistedMessage.session = persistedSession
            return persistedMessage
        }
        
        return persistedSession
    }
}

extension ChatMessage {
    func toPersistedMessage() -> PersistedChatMessage {
        PersistedChatMessage(
            id: id,
            content: content,
            isUser: isUser,
            timestamp: timestamp,
            reactions: reactions,
            processingTime: metadata?.processingTime,
            tokens: metadata?.tokens,
            confidence: metadata?.confidence
        )
    }
}

extension ChatSettings {
    func toPersistedSettings() -> PersistedChatSettings {
        PersistedChatSettings(
            selectedPersona: selectedPersona.rawValue,
            voiceEnabled: voiceEnabled,
            streamingEnabled: streamingEnabled,
            maxContextLength: maxContextLength,
            autoSaveConversations: autoSaveConversations
        )
    }
}
