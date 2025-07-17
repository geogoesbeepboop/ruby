//
//  PersistedChatSettings.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import SwiftData

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
        selectedPersona: String = AIPersona.none.rawValue,
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
            selectedPersona: AIPersona(rawValue: selectedPersona) ?? .none,
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
