import Foundation
import SwiftUI
import FoundationModels
import AVFoundation
import Speech
import os.log

@MainActor
@Observable
final class ChatStore {
    // MARK: - Core State Properties
    
    var currentState: ChatState = .activeChat
    var messages: [ChatMessage] = []
    var streamingContent: String? = nil
    var lastError: ChatError? = nil
    var settings: ChatSettings = .default
    var savedSessions: [ConversationSession] = []
    var currentSession: ConversationSession? = nil
    var isRecording: Bool = false
    
    // MARK: - Private Properties
    
    private var dataManager: DataManager
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var voiceInputTimer: Timer?
    private var sessionTitleUpdateTask: Task<Void, Never>?
    private var persistenceQueue = DispatchQueue(label: "com.ruby.chatstore.persistence", qos: .background)
    private var isInitialized = false
    private var pendingSaveOperations: Set<UUID> = []
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatStore")
    private let httpClient = HTTPClient()

    @ObservationIgnored
    private lazy var languageSession: LanguageModelSession = {
        LanguageModelSession(
            tools: [
                WeatherTool(),
                WebSearchTool(httpClient: self.httpClient),
                CalculatorTool(),
                ReminderTool(),
                DateTimeTool(),
                NewsTool(httpClient: self.httpClient)
            ],
            instructions: self.settings.selectedPersona.systemPrompt
        )
    }()
    @ObservationIgnored
    private lazy var titleGenerationSession: LanguageModelSession = {
        LanguageModelSession()
    }()
    
    var publicLanguageSession: LanguageModelSession {
        languageSession
    }
    
    // MARK: - Initialization
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        logger.info("🔧 [ChatStore] Initializing ChatStore")
        
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - AI Initialization
    
    func initializeAI() async {
        logger.info("🚀 [ChatStore] Starting AI initialization")
        
        do {
            self.isInitialized = true
            
            logger.info("✅ [ChatStore] AI initialization completed successfully")
            
            // Initialize new session if none exists
            if currentSession == nil {
                await startNewSession()
            }
            
        } catch {
            logger.error("❌ [ChatStore] AI initialization failed: \(error.localizedDescription)")
            self.lastError = .sessionInitializationFailed
            self.currentState = .error("Failed to initialize AI")
        }
    }
    
    // MARK: - Session Management
    
    func startNewSession() async {
        logger.info("🆕 [ChatStore] Starting new chat session")
        
        // Save current session if it has messages
        if let current = currentSession, !current.messages.isEmpty {
            await saveCurrentSessionSafely()
        }
        
        // Create new session
        let newSession = ConversationSession(
            id: UUID(),
            title: "New Conversation",
            createdAt: Date(),
            lastModified: Date(),
            messages: [defaultGreetingMessage()],
            persona: settings.selectedPersona
        )
        
        currentSession = newSession
        messages = []
        streamingContent = nil
        currentState = .activeChat
        lastError = nil
        
        logger.info("✅ [ChatStore] New session created with ID: \(newSession.id)")
        
        // Load saved sessions
        await loadSavedSessions()
    }
    
    func loadSession(_ session: ConversationSession) async {
        logger.info("📁 [ChatStore] Loading session: \(session.id)")
        
        // Save current session first if it has changes
        if let current = currentSession, !current.messages.isEmpty, current.id != session.id {
            await saveCurrentSessionSafely()
        }
        
        currentSession = session
        messages = session.messages
        streamingContent = nil
        currentState = .activeChat
        lastError = nil
        
        // Update settings to match session persona
        settings.selectedPersona = session.persona
        await saveSettingsAsync()
        
        logger.info("✅ [ChatStore] Session loaded successfully with \(session.messages.count) messages")
    }
    
    func deleteSession(_ session: ConversationSession) {
        logger.info("🗑️ [ChatStore] Deleting session: \(session.id)")
        
        Task {
            do {
                try await dataManager.deleteSession(withId: session.id)
                
                // Remove from saved sessions
                savedSessions.removeAll { $0.id == session.id }
                
                // If deleting current session, start new one
                if currentSession?.id == session.id {
                    await startNewSession()
                }
                
                logger.info("✅ [ChatStore] Session deleted successfully")
                
            } catch {
                logger.error("❌ [ChatStore] Failed to delete session: \(error.localizedDescription)")
                lastError = .saveFailed
            }
        }
    }
    
    // MARK: - Message Management
    
    func addMessage(_ message: ChatMessage) {
        logger.info("💬 [ChatStore] Adding \(message.isUser ? "user" : "AI") message")
        
        messages.append(message)
        
        // Update current session
        if var session = currentSession {
            session.messages = messages
            session.lastModified = Date()
            currentSession = session
            
            // Auto-save session in background
            Task {
                await saveCurrentSessionSafely()
                
                // Generate title for new sessions with user messages
                if message.isUser && session.messages.filter({ $0.isUser }).count == 1 {
                    await updateSessionTitle()
                }
            }
        }
        
        logger.info("✅ [ChatStore] Message added successfully")
    }
    
    func addReaction(to messageId: UUID, reaction: String) {
        logger.info("😀 [ChatStore] Adding reaction '\(reaction)' to message: \(messageId)")
        
        // Find and update the message
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            var message = messages[index]
            
            // Toggle reaction - remove if already exists, add if not
            if let reactionIndex = message.reactions.firstIndex(of: reaction) {
                message.reactions.remove(at: reactionIndex)
                logger.info("➖ [ChatStore] Removed reaction '\(reaction)'")
            } else {
                message.reactions.append(reaction)
                logger.info("➕ [ChatStore] Added reaction '\(reaction)'")
            }
            
            messages[index] = message
            
            // Update current session
            if var session = currentSession {
                session.messages = messages
                session.lastModified = Date()
                currentSession = session
                
                // Save changes in background
                Task {
                    await saveCurrentSessionSafely()
                }
            }
            
            logger.info("✅ [ChatStore] Reaction updated successfully")
        } else {
            logger.warning("⚠️ [ChatStore] Message not found for reaction: \(messageId)")
        }
    }
    
    func deleteMessage(_ message: ChatMessage) {
        logger.info("🗑️ [ChatStore] Deleting message: \(message.id)")
        
        messages.removeAll { $0.id == message.id }
        
        // Update current session
        if var session = currentSession {
            session.messages = messages
            session.lastModified = Date()
            currentSession = session
            
            // Save changes in background
            Task {
                await saveCurrentSessionSafely()
            }
        }
        
        // If no messages left, add a default greeting based on persona
        if messages.isEmpty {
            let greetingMessage = defaultGreetingMessage()
            addMessage(greetingMessage)
        }
        
        currentState = .activeChat
        logger.info("✅ [ChatStore] Message deleted successfully")
    }
    
    func saveAndEndSession() {
        logger.info("💾 [ChatStore] Saving and ending current session")
        
        Task {
            await saveCurrentSessionSafely()
            await startNewSession()
            logger.info("✅ [ChatStore] Session saved and new session started")
        }
    }
    
    private func defaultGreetingMessage() -> ChatMessage {
        let greeting: String
        
        switch settings.selectedPersona {
        case .none:
            greeting = "What's shakin, bacon?"
        case .therapist:
            greeting = "Hi there! What's on your mind today?"
        case .professor:
            greeting = "Hello! What would you like to explore and learn about today?"
        case .techLead:
            greeting = "Hey! What technical challenge can I help you tackle today?"
        case .musician:
            greeting = "Hello! Ready to dive into the world of music and creativity?"
        case .comedian:
            greeting = "Hey there! What's bringing you joy or stress today? Let's find the humor in it!"
        }
        
        return ChatMessage(
            content: greeting,
            isUser: false,
            timestamp: Date()
        )
    }
    
    // MARK: - Settings Management
    
    func updatePersona(_ persona: AIPersona) {
        logger.info("👤 [ChatStore] Updating persona to: \(persona.rawValue)")
        
        settings.selectedPersona = persona
        
        // Update current session persona
        if var session = currentSession {
            session.persona = persona
            currentSession = session
        }
        
        Task {
            await saveSettingsAsync()
            await saveCurrentSessionSafely()
        }
        
        logger.info("✅ [ChatStore] Persona updated successfully")
    }
    
    func updateSettings(_ newSettings: ChatSettings) {
        logger.info("⚙️ [ChatStore] Updating settings")
        
        let oldPersona = settings.selectedPersona
        settings = newSettings
        
        // If persona changed, update current session
        if oldPersona != newSettings.selectedPersona, var session = currentSession {
            session.persona = newSettings.selectedPersona
            currentSession = session
        }
        
        Task {
            await saveSettingsAsync()
            await saveCurrentSessionSafely()
        }
        
        logger.info("✅ [ChatStore] Settings updated successfully")
    }
    
    func saveSettings() {
        Task {
            await saveSettingsAsync()
        }
    }
    
    // MARK: - Voice Recording
    
    func startVoiceRecording() {
        logger.info("🎤 [ChatStore] Starting voice recording")
        
        guard !isRecording else {
            logger.warning("⚠️ [ChatStore] Voice recording already in progress")
            return
        }
        
        // Request permissions
        requestSpeechPermissions { [weak self] granted in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if granted {
                    self.setupVoiceRecording()
                } else {
                    self.logger.error("❌ [ChatStore] Speech recognition permission denied")
                    self.lastError = .permissionDenied
                }
            }
        }
    }
    
    func stopVoiceRecording() {
        logger.info("🛑 [ChatStore] Stopping voice recording")
        
        guard isRecording else {
            logger.warning("⚠️ [ChatStore] No active voice recording to stop")
            return
        }
        
        cleanupVoiceRecording()
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        logger.info("📥 [ChatStore] Loading initial data")
        
        await loadSettingsAsync()
        await loadSavedSessions()
        
        logger.info("✅ [ChatStore] Initial data loaded successfully")
    }
    
    private func loadSettingsAsync() async {
        do {
            let loadedSettings = try await dataManager.loadSettings()
            self.settings = loadedSettings
            logger.info("⚙️ [ChatStore] Settings loaded successfully")
        } catch {
            logger.error("❌ [ChatStore] Failed to load settings, using defaults: \(error.localizedDescription)")
            self.settings = .default
        }
    }
    
    private func saveSettingsAsync() async {
        do {
            try await dataManager.saveSettings(settings)
            logger.info("💾 [ChatStore] Settings saved successfully")
        } catch {
            logger.error("❌ [ChatStore] Failed to save settings: \(error.localizedDescription)")
            lastError = .saveFailed
        }
    }
    
    private func loadSavedSessions() async {
        do {
            let sessions = try await dataManager.loadSessions()
            self.savedSessions = sessions
            logger.info("📂 [ChatStore] Loaded \(sessions.count) saved sessions")
        } catch {
            logger.error("❌ [ChatStore] Failed to load sessions: \(error.localizedDescription)")
            self.savedSessions = []
            lastError = .loadFailed
        }
    }
    
    private func saveCurrentSessionSafely() async {
        guard let session = currentSession else {
            logger.debug("💭 [ChatStore] No current session to save")
            return
        }
        
        // Prevent duplicate save operations for the same session
        guard !pendingSaveOperations.contains(session.id) else {
            logger.debug("⏳ [ChatStore] Save operation already pending for session: \(session.id)")
            return
        }
        
        pendingSaveOperations.insert(session.id)
        logger.info("💾 [ChatStore] Saving current session: \(session.id)")
        
        defer {
            pendingSaveOperations.remove(session.id)
        }
        
        do {
            var sessionToSave = session
            sessionToSave.messages = messages
            sessionToSave.lastModified = Date()
            
            try await dataManager.saveSession(sessionToSave)
            
            // Update current session reference
            currentSession = sessionToSave
            
            // Update saved sessions list
            if let index = savedSessions.firstIndex(where: { $0.id == sessionToSave.id }) {
                savedSessions[index] = sessionToSave
            } else {
                savedSessions.insert(sessionToSave, at: 0)
            }
            
            logger.info("✅ [ChatStore] Session saved successfully")
            
        } catch {
            logger.error("❌ [ChatStore] Failed to save session: \(error.localizedDescription)")
            lastError = .saveFailed
        }
    }
    
    private func updateSessionTitle() async {
        guard let session = currentSession,
              let firstUserMessage = session.messages.first(where: { $0.isUser })?.content,
              session.title == "New Conversation" else {
            logger.debug("💭 [ChatStore] Session title update not needed")
            return
        }
        
        logger.info("📝 [ChatStore] Generating title for session: \(session.id)")
        
        // Cancel any pending title update
        sessionTitleUpdateTask?.cancel()
        
        sessionTitleUpdateTask = Task {
            do {
                let titleResponse = try await titleGenerationSession.respond(
                    to: "Generate a short, descriptive title (3-6 words) for this conversation: \(firstUserMessage)",
                    generating: SessionTitle.self,
                    options: GenerationOptions(temperature: 0.3)
                )
                
                let newTitle = titleResponse.content.title
                logger.info("📋 [ChatStore] Generated session title: '\(newTitle)'")
                
                // Update session title
                if var updatedSession = currentSession {
                    updatedSession.title = newTitle
                    currentSession = updatedSession
                    
                    await saveCurrentSessionSafely()
                }
                
            } catch {
                logger.error("❌ [ChatStore] Failed to generate session title: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Voice Recording Private Methods
    
    private func requestSpeechPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    completion(granted)
                }
            default:
                completion(false)
            }
        }
    }
    
    private func setupVoiceRecording() {
        do {
            logger.info("🔧 [ChatStore] Setting up voice recording session")
            
            audioEngine = AVAudioEngine()
            speechRecognizer = SFSpeechRecognizer()
            
            guard let audioEngine = audioEngine,
                  let speechRecognizer = speechRecognizer else {
                logger.error("❌ [ChatStore] Failed to initialize audio components")
                lastError = .voiceRecognitionFailed
                return
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                logger.error("❌ [ChatStore] Failed to create recognition request")
                lastError = .voiceRecognitionFailed
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        
                        // Post transcription update notification
                        NotificationCenter.default.post(
                            name: NSNotification.Name("VoiceTranscriptionUpdate"),
                            object: transcription
                        )
                        
                        self.logger.debug("🗣️ [ChatStore] Voice transcription: '\(transcription)'")
                    }
                    
                    if let error = error {
                        self.logger.error("❌ [ChatStore] Speech recognition error: \(error.localizedDescription)")
                        self.cleanupVoiceRecording()
                        self.lastError = .voiceRecognitionFailed
                    }
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            currentState = .voiceListening
            isRecording = true
            
            // Auto-stop after 30 seconds
            voiceInputTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
                self?.stopVoiceRecording()
            }
            
            logger.info("✅ [ChatStore] Voice recording started successfully")
            
        } catch {
            logger.error("❌ [ChatStore] Failed to setup voice recording: \(error.localizedDescription)")
            cleanupVoiceRecording()
            lastError = .voiceRecognitionFailed
        }
    }
    
    private func cleanupVoiceRecording() {
        logger.info("🧹 [ChatStore] Cleaning up voice recording")
        
        voiceInputTimer?.invalidate()
        voiceInputTimer = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        speechRecognizer = nil
        
        isRecording = false
        currentState = .activeChat
        
        logger.info("✅ [ChatStore] Voice recording cleanup completed")
    }
    
//    deinit {
//        logger.info("🔥 [ChatStore] ChatStore deinitializing")
//        
//        cleanupVoiceRecording()
//        sessionTitleUpdateTask?.cancel()
//    }
}

// MARK: - Extensions

extension ChatStore {
    
    func exportSession(_ session: ConversationSession) -> Data? {
        logger.info("📤 [ChatStore] Exporting session: \(session.id)")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(session)
            logger.info("✅ [ChatStore] Session exported successfully")
            return data
            
        } catch {
            logger.error("❌ [ChatStore] Failed to export session: \(error.localizedDescription)")
            lastError = .saveFailed
            return nil
        }
    }
    
    func importSession(from data: Data) async {
        logger.info("📥 [ChatStore] Importing session from data")
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let session = try decoder.decode(ConversationSession.self, from: data)
            
            // Save imported session
            try await dataManager.saveSession(session)
            
            // Add to saved sessions
            savedSessions.insert(session, at: 0)
            
            logger.info("✅ [ChatStore] Session imported successfully: \(session.id)")
            
        } catch {
            logger.error("❌ [ChatStore] Failed to import session: \(error.localizedDescription)")
            lastError = .loadFailed
        }
    }
    
    func clearAllData() async {
        logger.info("🗑️ [ChatStore] Clearing all data")
        
        do {
            try await dataManager.clearAllData()
            
            // Reset in-memory state
            savedSessions = []
            currentSession = nil
            messages = []
            streamingContent = nil
            currentState = .activeChat
            lastError = nil
            
            // Start fresh session
            await startNewSession()
            
            logger.info("✅ [ChatStore] All data cleared successfully")
            
        } catch {
            logger.error("❌ [ChatStore] Failed to clear all data: \(error.localizedDescription)")
            lastError = .saveFailed
        }
    }
}
struct GenerationOptionsFlavors {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    
    static let `default` = GenerationOptions(sampling: .greedy, temperature: 1)
    static let creative = GenerationOptions(sampling: .random(probabilityThreshold: 1.0), temperature: 2)
    static let precise = GenerationOptions(sampling: .greedy, temperature: 0.1)
}
