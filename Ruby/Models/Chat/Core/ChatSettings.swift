//
//  ChatSettings.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation

struct ChatSettings: Codable {
    var selectedPersona: AIPersona = .none
    var voiceEnabled: Bool = true
    var streamingEnabled: Bool = true
    var maxContextLength: Int = 8000
    var autoSaveConversations: Bool = true
    
    static let `default` = ChatSettings()
    
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
