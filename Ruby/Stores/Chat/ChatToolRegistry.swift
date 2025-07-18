import Foundation
import FoundationModels
import os.log

@Observable
@MainActor
final class ChatToolRegistry {
    // MARK: - Properties
    
    private(set) var availableTools: [any Tool] = []
    private(set) var enabledTools: Set<String> = []
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatToolRegistry")
    private let httpClient = HTTPClient()
    
    // MARK: - Initialization
    
    init() {
        logger.info("🔧 [ChatToolRegistry] Initializing ChatToolRegistry")
        registerDefaultTools()
    }
    
    // MARK: - Tool Registration
    
    private func registerDefaultTools() {
        logger.info("📋 [ChatToolRegistry] Registering default tools")
        
        let defaultTools: [any Tool] = [
            WeatherTool(),
            WebSearchTool(httpClient: httpClient),
            CalculatorTool(),
            ReminderTool(),
            DateTimeTool(),
            NewsTool(httpClient: httpClient)
        ]
        
        for tool in defaultTools {
            registerTool(tool)
        }
        
        // Enable all tools by default
        enabledTools = Set(availableTools.map { String(describing: type(of: $0)) })
        
        logger.info("✅ [ChatToolRegistry] Registered \(self.availableTools.count) default tools")
    }
    
    func registerTool(_ tool: any Tool) {
        let toolName = String(describing: type(of: tool))
        
        // Check if tool is already registered
        if availableTools.contains(where: { String(describing: type(of: $0)) == toolName }) {
            logger.warning("⚠️ [ChatToolRegistry] Tool '\(toolName)' already registered, skipping")
            return
        }
        
        availableTools.append(tool)
        logger.info("➕ [ChatToolRegistry] Registered tool: \(toolName)")
    }
    
    func unregisterTool<T: Tool>(_ toolType: T.Type) {
        let toolName = String(describing: toolType)
        
        availableTools.removeAll { String(describing: type(of: $0)) == toolName }
        enabledTools.remove(toolName)
        
        logger.info("➖ [ChatToolRegistry] Unregistered tool: \(toolName)")
    }
    
    // MARK: - Tool Management
    
    func enableTool<T: Tool>(_ toolType: T.Type) {
        let toolName = String(describing: toolType)
        
        if availableTools.contains(where: { String(describing: type(of: $0)) == toolName }) {
            enabledTools.insert(toolName)
            logger.info("✅ [ChatToolRegistry] Enabled tool: \(toolName)")
        } else {
            logger.warning("⚠️ [ChatToolRegistry] Cannot enable unregistered tool: \(toolName)")
        }
    }
    
    func disableTool<T: Tool>(_ toolType: T.Type) {
        let toolName = String(describing: toolType)
        enabledTools.remove(toolName)
        logger.info("❌ [ChatToolRegistry] Disabled tool: \(toolName)")
    }
    
    func isToolEnabled<T: Tool>(_ toolType: T.Type) -> Bool {
        let toolName = String(describing: toolType)
        return enabledTools.contains(toolName)
    }
    
    func getEnabledTools() -> [any Tool] {
        return availableTools.filter { tool in
            let toolName = String(describing: type(of: tool))
            return enabledTools.contains(toolName)
        }
    }
    
    func getAllTools() -> [any Tool] {
        return availableTools
    }
    
    // MARK: - Tool Configuration
    
    func configureToolSettings(_ settings: ToolSettings) {
        logger.info("⚙️ [ChatToolRegistry] Configuring tool settings")
        
        // Update enabled tools based on settings
        enabledTools.removeAll()
        
        if settings.weatherEnabled {
            enabledTools.insert("WeatherTool")
        }
        if settings.webSearchEnabled {
            enabledTools.insert("WebSearchTool")
        }
        if settings.calculatorEnabled {
            enabledTools.insert("CalculatorTool")
        }
        if settings.reminderEnabled {
            enabledTools.insert("ReminderTool")
        }
        if settings.dateTimeEnabled {
            enabledTools.insert("DateTimeTool")
        }
        if settings.newsEnabled {
            enabledTools.insert("NewsTool")
        }
        
        logger.info("✅ [ChatToolRegistry] Tool settings configured, \(self.enabledTools.count) tools enabled")
    }
    
    // MARK: - Debugging
    
    func printToolStatus() {
        logger.info("📊 [ChatToolRegistry] Tool Status:")
        logger.info("📊 [ChatToolRegistry] Available tools: \(self.availableTools.count)")
        logger.info("📊 [ChatToolRegistry] Enabled tools: \(self.enabledTools.count)")
        
        for tool in availableTools {
            let toolName = String(describing: type(of: tool))
            let status = enabledTools.contains(toolName) ? "✅ Enabled" : "❌ Disabled"
            logger.info("📊 [ChatToolRegistry] \(toolName): \(status)")
        }
    }
}

// MARK: - Tool Settings
struct ToolSettings {
    var weatherEnabled: Bool = true
    var webSearchEnabled: Bool = true
    var calculatorEnabled: Bool = true
    var reminderEnabled: Bool = true
    var dateTimeEnabled: Bool = true
    var newsEnabled: Bool = true
    
    static let `default` = ToolSettings()
    
    var enabledCount: Int {
        [weatherEnabled, webSearchEnabled, calculatorEnabled, reminderEnabled, dateTimeEnabled, newsEnabled]
            .filter { $0 }.count
    }
}
