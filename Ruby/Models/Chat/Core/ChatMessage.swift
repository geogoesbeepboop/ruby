//
//  ChatMessage.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    var reactions: [String] = []
    var metadata: MessageMetadata?
    
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
