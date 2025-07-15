import Foundation
import AppIntents
import Combine
/// Manager class to handle LLM tool calls that trigger App Intents
@MainActor
class IntentToolManager: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    static let shared = IntentToolManager()
    
    // Map of available tools to intents
    private let toolIntentMap: [String: any LotusAppIntent.Type] = [
        "navigate_to_tab": NavigateToTabIntent.self,
        "start_new_chat": StartNewChatIntent.self,
        "send_message": SendMessageIntent.self,
        "change_persona": ChangePersonaIntent.self,
        "toggle_setting": ToggleSettingIntent.self,
        "start_voice_input": TriggerVoiceInputIntent.self
    ]
    
    private init() {}
    
    // Execute intent from LLM tool call
    func executeIntent(toolName: String, parameters: [String: Any]) async throws -> String {
        print("🛠️ [IntentToolManager] ================================")
        print("🛠️ [IntentToolManager] EXECUTING INTENT")
        print("🛠️ [IntentToolManager] Tool Name: '\(toolName)'")
        print("🛠️ [IntentToolManager] Parameters: \(parameters)")
        print("🛠️ [IntentToolManager] Available tools: \(Array(toolIntentMap.keys))")
        
        guard let intentType = toolIntentMap[toolName] else {
            print("❌ [IntentToolManager] Unknown tool: \(toolName)")
            print("❌ [IntentToolManager] Available tools: \(Array(toolIntentMap.keys).joined(separator: ", "))")
            throw IntentError.unknownTool(toolName)
        }
        
        print("✅ [IntentToolManager] Found intent type: \(intentType)")
        
        // Create intent instance with parameters
        let intent = try createIntentInstance(type: intentType, parameters: parameters)
        print("✅ [IntentToolManager] Created intent instance: \(type(of: intent))")
        
        // Execute the intent
        print("🚀 [IntentToolManager] Executing intent...")
        let result = try await intent.perform()
        print("✅ [IntentToolManager] Intent execution completed")
        
        let resultString = "Successfully executed \(toolName): \(extractResultValue(from: result))"
        print("📝 [IntentToolManager] Result: \(resultString)")
        print("🛠️ [IntentToolManager] ================================")
        
        return resultString
    }
    
    private func createIntentInstance(type: any LotusAppIntent.Type, parameters: [String: Any]) throws -> any LotusAppIntent {
        switch type {
        case is NavigateToTabIntent.Type:
            var intent = NavigateToTabIntent()
            if let tabString = parameters["tab"] as? String,
               let tab = AppTab(rawValue: tabString) {
                intent.targetTab = tab
            } else {
                throw IntentError.invalidParameters
            }
            return intent
            
        case is StartNewChatIntent.Type:
            return StartNewChatIntent()
            
        case is SendMessageIntent.Type:
            var intent = SendMessageIntent()
            guard let message = parameters["message"] as? String else {
                throw IntentError.invalidParameters
            }
            intent.messageText = message
            return intent
            
        case is ChangePersonaIntent.Type:
            var intent = ChangePersonaIntent()
            if let personaString = parameters["persona"] as? String,
               let persona = AppPersona(rawValue: personaString) {
                intent.persona = persona
            } else {
                throw IntentError.invalidParameters
            }
            return intent
            
        case is ToggleSettingIntent.Type:
            var intent = ToggleSettingIntent()
            guard let settingString = parameters["setting"] as? String,
                  let setting = AppSetting(rawValue: settingString),
                  let enable = parameters["enable"] as? Bool else {
                throw IntentError.invalidParameters
            }
            intent.setting = setting
            intent.enable = enable
            return intent
            
        case is TriggerVoiceInputIntent.Type:
            return TriggerVoiceInputIntent()
            
        default:
            throw IntentError.unsupportedIntent
        }
    }
    
    private func extractResultValue(from result: any IntentResult) -> String {
        // Extract meaningful result from IntentResult
        return "completed"
    }
}

// MARK: - LLM Tool Definitions

extension IntentToolManager {
    static let availableTools: [LLMToolDefinition] = [
        LLMToolDefinition(
            name: "navigate_to_tab",
            description: "Navigate to a specific tab in the app (Home or Chat)",
            parameters: [
                "tab": ToolParameter(
                    type: "string",
                    description: "The tab to navigate to",
                    required: true,
                    enumValues: ["Home", "Chat"]
                )
            ]
        ),
        LLMToolDefinition(
            name: "start_new_chat",
            description: "Start a new chat conversation session",
            parameters: [:]
        ),
        LLMToolDefinition(
            name: "send_message",
            description: "Send a message in the current chat",
            parameters: [
                "message": ToolParameter(
                    type: "string",
                    description: "The message text to send",
                    required: true,
                    enumValues: nil
                )
            ]
        ),
        LLMToolDefinition(
            name: "change_persona",
            description: "Change the AI personality/persona",
            parameters: [
                "persona": ToolParameter(
                    type: "string",
                    description: "The persona to switch to",
                    required: true,
                    enumValues: ["Welcoming Therapist", "Distinguished Professor", "Tech Lead", "World-Class Musician", "Wise Comedian"]
                )
            ]
        ),
        LLMToolDefinition(
            name: "toggle_setting",
            description: "Enable or disable app settings",
            parameters: [
                "setting": ToolParameter(
                    type: "string",
                    description: "The setting to toggle",
                    required: true,
                    enumValues: ["Voice Input", "Streaming Responses", "Auto-save Conversations"]
                ),
                "enable": ToolParameter(
                    type: "boolean",
                    description: "Whether to enable or disable the setting",
                    required: true,
                    enumValues: nil
                )
            ]
        ),
        LLMToolDefinition(
            name: "start_voice_input",
            description: "Start voice recording for chat input",
            parameters: [:]
        )
    ]
}

// MARK: - Supporting Types

struct LLMToolDefinition {
    let name: String
    let description: String
    let parameters: [String: ToolParameter]
}

struct ToolParameter {
    let type: String
    let description: String
    let required: Bool
    let enumValues: [String]?
}

enum IntentError: Error {
    case unknownTool(String)
    case unsupportedIntent
    case invalidParameters
    
    var localizedDescription: String {
        switch self {
        case .unknownTool(let tool):
            return "Unknown tool: \(tool)"
        case .unsupportedIntent:
            return "Unsupported intent type"
        case .invalidParameters:
            return "Invalid parameters provided"
        }
    }
}

// MARK: - Manager Classes

class ChatStoreManager {
    static let shared = ChatStoreManager()
    private init() {}
    
    weak var chatStore: ChatStore?
    
    func startNewSession() async {
        await chatStore?.startNewSession()
        print("🔄 [ChatStoreManager] Started new session")
    }
    
    func sendMessage(_ message: String) async {
        await chatStore?.sendMessage(message)
        print("💬 [ChatStoreManager] Sent message: \(message)")
    }
    
    func changePersona(to persona: AIPersona) async {
        chatStore?.updatePersona(persona)
        print("🎭 [ChatStoreManager] Changed persona to: \(persona.rawValue)")
    }
    
    func startVoiceInput() async {
        chatStore?.startVoiceRecording()
        print("🎤 [ChatStoreManager] Started voice input")
    }
}

class SettingsManager {
    static let shared = SettingsManager()
    private init() {}
    
    weak var chatStore: ChatStore?
    
    func updateSetting(_ setting: AppSetting, enabled: Bool) async {
        guard let store = chatStore else { return }
        
        switch setting {
        case .voiceInput:
            store.settings.voiceEnabled = enabled
        case .streaming:
            store.settings.streamingEnabled = enabled
        case .autoSave:
            store.settings.autoSaveConversations = enabled
        }
        
        print("⚙️ [SettingsManager] \(setting.rawValue): \(enabled)")
    }
}
