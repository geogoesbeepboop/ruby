//
//  PersistedChatSession.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import SwiftData

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
            persona: AIPersona(rawValue: persona) ?? .none
        )
    }
}
