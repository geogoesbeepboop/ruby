import AVFoundation
import Foundation
import FoundationModels
import Speech
import SwiftData
import SwiftUI

@Observable
@MainActor
class ChatStore {
    // MARK: - Published State

    var currentState: ChatState = .activeChat
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isRecording: Bool = false
    var voiceWaveform: [Float] = Array(repeating: 0.0, count: 50)
    var streamingContent: String?
    var currentSession: ConversationSession?
    var settings = ChatSettings.default
    var generationOptions = GenerationOptionsFlavors.default
    var lastError: ChatError?
    var savedSessions: [ConversationSession] = []
    
    // MARK: - Private Properties
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
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var waveformTimer: Timer?
    private let dataManager = DataManager.shared
    
    // MARK: - Enhanced Services

    private let personaContextService = PersonaContextService()
    private let httpClient = HTTPClient()
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        requestPermissions()
        loadPersistedData()
        // Set up automatic saving when app goes to background
        setupBackgroundSaving()
    }
    
    // MARK: - Public Properties
    
    var publicLanguageSession: LanguageModelSession {
        return languageSession
    }
    
    // MARK: - Public Methods
    
    func addMessage(_ message: ChatMessage) {
        print("💬 [MESSAGE-ADD] Adding \(message.isUser ? "user" : "AI") message to session")
        messages.append(message)
        
        // Auto-create session if this is the first user message
        if currentSession == nil && message.isUser {
            print("🆕 [SESSION-CREATE] Creating new session for first user message")
            createSessionFromCurrentMessages()
        } else if let session = currentSession {
            // Update existing session
            var updatedSession = session
            updatedSession.messages = messages
            updatedSession.lastModified = Date()
            currentSession = updatedSession
            
            // Background auto-save using the same reliable logic as save button
            print("💾 [AUTO-SAVE] Performing background auto-save after message")
            saveCurrentSessionSynchronously()
            
            // Trigger title generation for new sessions after AI response
            let userMessageCount = messages.filter({ $0.isUser }).count
            let aiMessageCount = messages.filter({ !$0.isUser }).count
            
            // Generate title after first AI response or after 3 exchanges
            if (!message.isUser && aiMessageCount == 1) || (userMessageCount >= 3 && updatedSession.title.contains("...")) {
                print("🏷️ [TITLE-TRIGGER] Triggering auto title generation")
                titleGenerationTask?.cancel()
                titleGenerationTask = Task { [weak self] in
                    await self?.generateAndUpdateTitleAsync()
                }
            }
        }
        
        print("✅ [MESSAGE-SAVED] Message saved successfully, total messages: \(messages.count)")
    }
    
    func initializeAI() async {
        print("🤖 [ChatStore] initializeAI called")
        do {
            print("🔄 [ChatStore] Creating new LanguageModelSession with instructions")
            // Prewarm the language model session for better performance
            print("🔥 [ChatStore] Prewarming language model session...")
            languageSession.prewarm()
            
            if messages.isEmpty {
                print("👋 [ChatStore] Adding default therapeutic greeting message")
                // Add default therapeutic greeting message
                let defaultMessage = ChatMessage(
                    content: "Hi there! What's on your mind today?",
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(defaultMessage)
            } else {
                print("💬 [ChatStore] Messages already exist (\(messages.count) messages)")
            }
            
            currentState = .activeChat
            print("✅ [ChatStore] AI initialization completed successfully")
        } catch {
            print("❌ [ChatStore] AI initialization failed: \(error.localizedDescription)")
            lastError = .sessionInitializationFailed
            currentState = .error("Failed to initialize AI") // Keep error state for initialization failures
        }
    }
    
    
    func startVoiceRecording() {
        print("🎤 [ChatStore] startVoiceRecording called")
        guard !isRecording else {
            print("⚠️ [ChatStore] Already recording, ignoring")
            return
        }
        
        print("▶️ [ChatStore] Starting voice recording - changing state to voiceListening")
        currentState = .voiceListening
        isRecording = true
        currentInput = "" // Clear previous input
        
        Task {
            await startSpeechRecognition()
        }
    }
    
    func stopVoiceRecording() {
        print("🚫 [ChatStore] stopVoiceRecording called")
        guard isRecording else {
            print("⚠️ [ChatStore] Not currently recording, ignoring")
            return
        }
        
        print("🛑 [ChatStore] Stopping voice recording")
        isRecording = false
        currentState = .activeChat // Always reset to active chat first
        stopSpeechRecognition()
        
        // Don't automatically send the message - let user decide
        print("✅ [ChatStore] Voice recording stopped, transcribed text available for user to send manually")
    }
    
    func startNewSession() {
        messages.removeAll()
        streamingContent = ""
        currentInput = ""
        currentSession = nil
        
        // Reset Foundation Models session with fresh instructions
        languageSession = LanguageModelSession(instructions: settings.selectedPersona.systemPrompt)
        currentState = .activeChat
        
        // Prewarm the new session for better performance
        Task {
            languageSession.prewarm()
        }
    }
    
    func saveAndEndSession() {
        // Save current session if it exists or create one if there are messages
        if currentSession == nil && !messages.filter({ $0.isUser }).isEmpty {
            createSessionFromCurrentMessages()
        } else if let session = currentSession {
            var updatedSession = session
            updatedSession.messages = messages
            
            // Don't block saving with title generation - do it async after save
            saveSession(updatedSession)
            
            // Generate title in background after saving
            titleGenerationTask?.cancel()
            titleGenerationTask = Task { [weak self] in
                await self?.generateAndUpdateTitleAsync()
            }
        }
        
        // Start a fresh session
        startNewSession()
    }
    
    func addReaction(to messageId: UUID, reaction: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            if !messages[index].reactions.contains(reaction) {
                messages[index].reactions.append(reaction)
            }
        }
    }
    
    func deleteMessage(with id: UUID) {
        messages.removeAll { $0.id == id }
        if messages.isEmpty {
            // Add default therapeutic greeting message
            let defaultMessage = ChatMessage(
                content: "Hi there! What's on your mind today?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(defaultMessage)
        }
        currentState = .activeChat
    }
    
    func updatePersona(_ persona: AIPersona) {
        settings.selectedPersona = persona
        // Reset session to apply new persona
        languageSession = LanguageModelSession()
    }
    
    func updateGenerationOptions(_ options: GenerationOptions) {
        generationOptions = options
        print("🎛️ [ChatStore] Updated generation options - Temperature: \(options.temperature ?? 0.0), Max Tokens: \(options.maximumResponseTokens ?? 0)")
    }
    
    func regenerateSessionTitle() {
        // Start async title generation
        titleGenerationTask?.cancel()
        titleGenerationTask = Task { [weak self] in
            await self?.generateAndUpdateTitleAsync()
        }
    }
    
    // MARK: - Async Title Generation
    
    @MainActor
    private func generateAndUpdateTitleAsync() async {
        guard let session = currentSession else { return }
        
        print("🏷️ [ChatStore] Starting async title generation for session: \(session.id)")
        
        // Generate title in background without blocking
        let newTitle = await generateAITitleAsync()
        
        // Update session with new title
        var updatedSession = session
        updatedSession.title = newTitle
        currentSession = updatedSession
        
        // Update in saved sessions array
        if let index = savedSessions.firstIndex(where: { $0.id == session.id }) {
            savedSessions[index] = updatedSession
        }
        
        saveCurrentSession()
        print("✅ [ChatStore] Async title generation completed: '\(newTitle)'")
    }
    
    private func generateAITitleAsync() async -> String {
        // Find messages for context
        let userMessages = messages.filter { $0.isUser }.prefix(3)
        let aiMessages = messages.filter { !$0.isUser }.prefix(3)
        
        guard !userMessages.isEmpty else {
            return "New Conversation"
        }
        
        // Create conversation context for title generation
        let allMessages = (Array(userMessages) + Array(aiMessages)).sorted { $0.timestamp < $1.timestamp }
        var conversationContext = ""
        for message in allMessages.prefix(6) {
            let sender = message.isUser ? "User" : "AI"
            conversationContext += "\(sender): \(message.content)\n"
        }
        
        let titlePrompt = """
        Based on this conversation, generate a concise, descriptive title that captures the main topic or theme:
        
        \(conversationContext)
        
        Requirements:
        - 3-6 words maximum
        - Descriptive and specific to the conversation content
        - Avoid generic words like "conversation", "chat", "discussion"
        - Focus on the main subject matter or theme
        
        Examples: "Travel Planning", "Recipe Help", "Career Advice", "Math Homework"
        """
        
        do {
            print("🔄 [ChatStore] Sending async title generation request...")
            let titleResponse = try await titleGenerationSession.respond(
                to: titlePrompt,
                generating: SessionTitle.self
            )
            
            let generatedTitle = titleResponse.content.title.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("📝 [ChatStore] Async AI responded with title: '\(generatedTitle)' (confidence: \(titleResponse.content.confidence))")
            
            // Use AI title if it's good quality
            if titleResponse.content.confidence >= 0.5 && generatedTitle.count <= 50 && !generatedTitle.isEmpty {
                return generatedTitle
            } else if generatedTitle.count > 50 {
                return String(generatedTitle.prefix(47)) + "..."
            }
        } catch {
            print("❌ [ChatStore] Async title generation failed: \(error.localizedDescription)")
        }
        
        return generateFallbackTitle()
    }
    
    private func generateFallbackTitle() -> String {
        let userMessages = messages.filter { $0.isUser }.prefix(2)
        
        guard let firstUserMessage = userMessages.first else {
            return "New Conversation"
        }
        
        let content = firstUserMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract key topics/themes from the message
        let words = content.split(separator: " ").map { String($0) }
        let stopWords = Set(["i", "me", "my", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by"])
        
        let significantWords = words.filter { word in
            word.count > 2 && !stopWords.contains(word.lowercased())
        }.prefix(4)
        
        if !significantWords.isEmpty {
            let title = significantWords.joined(separator: " ")
            return title.count > 40 ? String(title.prefix(37)) + "..." : title
        }
        
        // Final fallback
        if content.count <= 30 {
            return content.isEmpty ? "New Conversation" : content
        }
        
        return String(content.prefix(30)) + "..."
    }
    
    // MARK: - Private Methods
    
    
    // MARK: - Voice Recognition
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    private func startSpeechRecognition() async {
        guard let speechRecognizer = SFSpeechRecognizer(),
              speechRecognizer.isAvailable
        else {
            lastError = .voiceRecognitionFailed
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            
            // Update waveform visualization
            self.updateWaveform(from: buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                print("📝 [ChatStore] Speech recognition result: '\(transcription)'")
                DispatchQueue.main.async {
                    self.currentInput = transcription
                    // Update real-time transcription for the text field
                    NotificationCenter.default.post(
                        name: NSNotification.Name("VoiceTranscriptionUpdate"),
                        object: transcription
                    )
                }
            }
            
            if let error = error {
                print("❌ [ChatStore] Speech recognition error: \(error.localizedDescription)")
                self.stopSpeechRecognition()
            }
        }
        
        startWaveformTimer()
    }
    
    private func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        stopWaveformTimer()
    }
    
    private func updateWaveform(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameLength = Int(buffer.frameLength)
        let sampleStep = max(1, frameLength / voiceWaveform.count)
        
        for i in 0..<voiceWaveform.count {
            let sampleIndex = i * sampleStep
            if sampleIndex < frameLength {
                voiceWaveform[i] = abs(channelData[sampleIndex])
            }
        }
    }
    
    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if !self.isRecording {
                // Gradually decay waveform when not recording
                for i in 0..<self.voiceWaveform.count {
                    self.voiceWaveform[i] *= 0.95
                }
            }
        }
    }
    
    private func stopWaveformTimer() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        
        // Reset waveform
        voiceWaveform = Array(repeating: 0.0, count: 50)
    }
    
    // MARK: - Data Persistence Methods
    
    private func loadPersistedData() {
        Task {
            do {
                // Load settings
                settings = try dataManager.loadSettings()
                
                // Load saved sessions
                savedSessions = try dataManager.loadSessions()
                
                // If we have saved sessions, load the most recent one
                if let mostRecentSession = savedSessions.first {
                    await loadSession(mostRecentSession)
                }
            } catch {
                print("Failed to load persisted data: \(error)")
                lastError = .loadFailed
            }
        }
    }
    
    func saveCurrentSession() {
        guard let session = currentSession else { return }
        var sessionToSave = session
        sessionToSave.lastModified = Date() // Update lastModified only when actually saving
        currentSession = sessionToSave
        saveSession(sessionToSave)
    }
    
    private func saveCurrentSessionSynchronously() {
        guard let session = currentSession else { return }
        print("💾 [ChatStore] Saving session synchronously with \(session.messages.count) messages")
        
        var sessionToSave = session
        sessionToSave.lastModified = Date()
        currentSession = sessionToSave
        
        // Save synchronously to prevent data loss
        do {
            try dataManager.saveSession(sessionToSave)
            
            // Update the session in savedSessions array
            if let index = savedSessions.firstIndex(where: { $0.id == sessionToSave.id }) {
                savedSessions[index] = sessionToSave
            } else {
                savedSessions.insert(sessionToSave, at: 0)
            }
            
            print("✅ [ChatStore] Session saved successfully")
        } catch {
            print("❌ [ChatStore] Failed to save session synchronously: \(error)")
            // Fallback to async save
            saveSession(sessionToSave)
        }
    }
    
    func saveSession(_ session: ConversationSession) {
        do {
            var sessionToSave = session
            sessionToSave.lastModified = Date() // Ensure lastModified is current when saving
            try dataManager.saveSession(sessionToSave)
            // Update the session in savedSessions array
            if let index = savedSessions.firstIndex(where: { $0.id == sessionToSave.id }) {
                savedSessions[index] = sessionToSave
            } else {
                savedSessions.insert(sessionToSave, at: 0)
            }
            print("✅ [ChatStore] Session saved successfully")
        } catch {
            print("❌ [ChatStore] Failed to save session: \(error)")
            lastError = .saveFailed
        }
    }
    
    func saveSettings() {
        do {
            try dataManager.saveSettings(settings)
            print("✅ [ChatStore] Settings saved successfully")
        } catch {
            print("❌ [ChatStore] Failed to save settings: \(error)")
            lastError = .saveFailed
        }
    }
    
    func loadSession(_ session: ConversationSession) async {
        // Save current session before switching if there are unsaved changes
        if let current = currentSession, !messages.isEmpty {
            var updatedCurrent = current
            updatedCurrent.messages = messages
            // lastModified will be set in saveSession()
            saveSession(updatedCurrent)
        }
        
        currentSession = session
        messages = session.messages
        settings.selectedPersona = session.persona
        
        // Only add default greeting for truly empty new sessions, not saved sessions
        if messages.isEmpty && session.messages.isEmpty {
            // Add default therapeutic greeting message for new sessions only
            let defaultMessage = ChatMessage(
                content: "Hi there! What's on your mind today?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(defaultMessage)
        }
        currentState = .activeChat
        
        // Update the session in savedSessions array (don't modify lastModified when just loading)
        if let index = savedSessions.firstIndex(where: { $0.id == session.id }) {
            savedSessions[index] = session
        }
        
        // Reinitialize language session with new persona
        languageSession = LanguageModelSession()
    }
    
    func deleteSession(_ session: ConversationSession) {
        do {
            try dataManager.deleteSession(withId: session.id)
            savedSessions.removeAll { $0.id == session.id }
            
            // If this was the current session, start a new one
            if currentSession?.id == session.id {
                startNewSession()
            }
            print("✅ [ChatStore] Session deleted successfully")
        } catch {
            print("❌ [ChatStore] Failed to delete session: \(error)")
            lastError = .saveFailed
        }
    }
    
    func createSessionFromCurrentMessages() {
        guard !messages.isEmpty else { return }
        
        // Use the timestamp of the last message as the initial lastModified
        let lastMessageTime = messages.last?.timestamp ?? Date()
        
        // Start with a simple fallback title - AI title will be generated async
        let temporaryTitle = generateFallbackTitle()
        
        let session = ConversationSession(
            title: temporaryTitle,
            createdAt: messages.first?.timestamp ?? Date(),
            lastModified: lastMessageTime,
            messages: messages,
            persona: settings.selectedPersona
        )
        
        currentSession = session
        savedSessions.insert(session, at: 0)
        saveCurrentSessionSynchronously()
        print("✅ [ChatStore] New session created and saved immediately")
    }
    
    func exportConversations() -> Data? {
        do {
            return try dataManager.exportAllData()
        } catch {
            print("Failed to export data: \(error)")
            lastError = .saveFailed
            return nil
        }
    }
    
    func importConversations(from data: Data) {
        do {
            try dataManager.importData(data)
            Task {
                await loadPersistedData() // Reload after import
            }
            print("✅ [ChatStore] Data imported successfully")
        } catch {
            print("❌ [ChatStore] Failed to import data: \(error)")
            lastError = .loadFailed
        }
    }
    
    func clearAllData() {
        do {
            try dataManager.clearAllData()
            // Reset in-memory state
            savedSessions.removeAll()
            currentSession = nil
            startNewSession()
            settings = ChatSettings.default
            print("✅ [ChatStore] All data cleared successfully")
        } catch {
            print("❌ [ChatStore] Failed to clear data: \(error)")
            lastError = .saveFailed
        }
    }
    
    
    // MARK: - Background Saving
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var titleGenerationTask: Task<Void, Never>?
    
    private func setupBackgroundSaving() {
        // Save when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppGoingToBackground()
        }
        
        // Save when app terminates
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppTermination()
        }
        
        // Note: Removed periodic auto-save since we now save after each message
        // This improves performance by eliminating unnecessary saves
    }
    
    private func handleAppGoingToBackground() {
        print("📱 [ChatStore] App going to background, initiating protected save...")
        
        // Begin background task to ensure save completes
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SaveChatSession") { [weak self] in
            // Cleanup when background time expires
            self?.endBackgroundTask()
        }
        
        // Perform synchronous save with background task protection
        saveCurrentSessionSynchronously()
        
        // End background task after save completes
        endBackgroundTask()
    }
    
    private func handleAppTermination() {
        print("📱 [ChatStore] App terminating, performing critical save...")
        
        // Force immediate synchronous save - no background task needed for termination
        saveCurrentSessionSynchronously()
        
        // Cancel any pending async operations that could cause data loss
        cancelPendingOperations()
    }
    
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    private func cancelPendingOperations() {
        // Cancel any pending title generation tasks
        titleGenerationTask?.cancel()
        titleGenerationTask = nil
        print("🚫 [ChatStore] Cancelled pending async operations...")
    }
}

// MARK: - Generation Options Configuration
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

