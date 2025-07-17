//
//  PersistedChatMessage.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import SwiftData

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
        message.metadata = MessageMetadata(
            processingTime: processingTime,
            tokens: tokens,
            confidence: confidence
        )
        return message
    }
}
