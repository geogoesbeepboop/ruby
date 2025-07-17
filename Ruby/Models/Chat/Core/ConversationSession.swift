//
//  ConversationSession.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation

struct ConversationSession: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var lastModified: Date
    var messages: [ChatMessage]
    var persona: AIPersona
    
    init(id: UUID = UUID(), title: String, createdAt: Date, lastModified: Date, messages: [ChatMessage], persona: AIPersona) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.messages = messages
        self.persona = persona
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var lastMessage: ChatMessage? {
        messages.last
    }
    
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
