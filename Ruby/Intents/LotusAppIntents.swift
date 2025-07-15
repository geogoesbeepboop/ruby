import AppIntents
import SwiftUI

// MARK: - Base Protocol for All App Intents

protocol LotusAppIntent: AppIntent {
    var category: IntentCategory { get }
    var requiresOpenApp: Bool { get }
}

enum IntentCategory: String {
    case navigation = "Navigation"
    case chat = "Chat"
    case settings = "Settings"
    case ui = "UI Interaction"
}

// MARK: - Navigation Intents

struct NavigateToTabIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Navigate to Tab"
    static let description: LocalizedStringResource = "Navigate to a specific tab in the app"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Tab")
    var targetTab: AppTab
    
    var category: IntentCategory { .navigation }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Use existing notification system for tab switching
        let notification: Notification.Name = targetTab == .chat
            ? Notification.Name.switchToChatTab
            : Notification.Name.switchToHomeTab
        NotificationCenter.default.post(name: notification, object: nil)
        return .result(value: "Navigated to \(targetTab.rawValue) tab")
    }
}

enum AppTab: String, AppEnum, CaseIterable {
    case home = "Home"
    case chat = "Chat"
    
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "App Tab")
    }

    nonisolated static var caseDisplayRepresentations: [AppTab: DisplayRepresentation] {
        [
            .home: DisplayRepresentation(stringLiteral: "Home"),
            .chat: DisplayRepresentation(stringLiteral: "Chat")
        ]
    }
}

// MARK: - Chat Control Intents

struct StartNewChatIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Start New Chat"
    static let description: LocalizedStringResource = "Begin a new conversation"
    static let openAppWhenRun: Bool = true
    
    var category: IntentCategory { .chat }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Access ChatStore through shared instance
        await ChatStoreManager.shared.startNewSession()
        NotificationCenter.default.post(name: .switchToChatTab, object: nil)
        return .result(value: "Started new chat session")
    }
}

struct SendMessageIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Send Message"
    static let description: LocalizedStringResource = "Send a message in the current chat"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Message")
    var messageText: String
    
    var category: IntentCategory { .chat }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await ChatStoreManager.shared.sendMessage(messageText)
        return .result(value: "Message sent: \(messageText)")
    }
}

struct ChangePersonaIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Change AI Persona"
    static let description: LocalizedStringResource = "Switch to a different AI personality"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Persona")
    var persona: AppPersona
    
    var category: IntentCategory { .chat }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let aiPersona = AIPersona(rawValue: persona.rawValue) ?? .therapist
        await ChatStoreManager.shared.changePersona(to: aiPersona)
        return .result(value: "Changed persona to \(persona.rawValue)")
    }
}

enum AppPersona: String, AppEnum, CaseIterable, Sendable {
    case therapist = "Welcoming Therapist"
    case professor = "Distinguished Professor"
    case techLead = "Tech Lead"
    case musician = "World-Class Musician"
    case comedian = "Wise Comedian"
    
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "AI Persona")
    }
    static var caseDisplayRepresentations: [AppPersona: DisplayRepresentation] = [
        .therapist: "Welcoming Therapist",
        .professor: "Distinguished Professor",
        .techLead: "Tech Lead",
        .musician: "World-Class Musician",
        .comedian: "Wise Comedian"
    ]
}

// MARK: - Settings Control Intents

struct ToggleSettingIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Toggle Setting"
    static let description: LocalizedStringResource = "Enable or disable app settings"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Setting")
    var setting: AppSetting
    
    @Parameter(title: "Enable")
    var enable: Bool
    
    var category: IntentCategory { .settings }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        await SettingsManager.shared.updateSetting(setting, enabled: enable)
        let action = enable ? "Enabled" : "Disabled"
        return .result(value: "\(action) \(setting.rawValue)")
    }
}

enum AppSetting: String, AppEnum, CaseIterable, Sendable {
    case voiceInput = "Voice Input"
    case streaming = "Streaming Responses"
    case autoSave = "Auto-save Conversations"
    
    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "App Setting")
    }
    static var caseDisplayRepresentations: [AppSetting: DisplayRepresentation] = [
        .voiceInput: "Voice Input",
        .streaming: "Streaming Responses",
        .autoSave: "Auto-save Conversations"
    ]
}

// MARK: - UI Control Intents

struct TriggerVoiceInputIntent: LotusAppIntent {
    static let title: LocalizedStringResource = "Start Voice Input"
    static let description: LocalizedStringResource = "Begin voice recording for chat input"
    static let openAppWhenRun: Bool = true
    
    var category: IntentCategory { .ui }
    var requiresOpenApp: Bool { true }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Navigate to chat and trigger voice input
        NotificationCenter.default.post(name: .switchToChatTab, object: nil)
        await ChatStoreManager.shared.startVoiceInput()
        return .result(value: "Started voice input")
    }
}

// MARK: - Shortcuts Provider

struct LotusShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NavigateToTabIntent(),
            phrases: [
                "Go to \(\.$targetTab) in \(.applicationName)",
                "Open \(\.$targetTab) tab in \(.applicationName)",
                "Switch to \(\.$targetTab) in \(.applicationName)"
            ],
            shortTitle: "Navigate",
            systemImageName: "arrow.right.circle"
        )
        
        AppShortcut(
            intent: StartNewChatIntent(),
            phrases: [
                "Start new chat in \(.applicationName)",
                "Begin conversation in \(.applicationName)",
                "New chat session in \(.applicationName)"
            ],
            shortTitle: "New Chat",
            systemImageName: "message.circle"
        )
        
        AppShortcut(
            intent: ChangePersonaIntent(),
            phrases: [
                "Change to \(\.$persona) in \(.applicationName)",
                "Switch to \(\.$persona) persona in \(.applicationName)",
                "Use \(\.$persona) in \(.applicationName)"
            ],
            shortTitle: "Change Persona",
            systemImageName: "person.circle"
        )
        
        AppShortcut(
            intent: TriggerVoiceInputIntent(),
            phrases: [
                "Start voice input in \(.applicationName)",
                "Record voice message in \(.applicationName)",
                "Voice chat in \(.applicationName)"
            ],
            shortTitle: "Voice Input",
            systemImageName: "mic.circle"
        )
    }
}
