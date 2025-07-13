import Foundation
import SwiftUI
import SwiftData
import FoundationModels
import AVFoundation
import Speech

@Observable
@MainActor
class ChatStore {
    // MARK: - Published State
    var currentState: ChatState = .activeChat
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isRecording: Bool = false
    var voiceWaveform: [Float] = Array(repeating: 0.0, count: 50)
    var isAITyping: Bool = false
    var streamingContent: String = ""
    var currentSession: ConversationSession?
    var settings = ChatSettings.default
    var lastError: ChatError?
    var savedSessions: [ConversationSession] = []
    
    // MARK: - Private Properties
    private var languageSession: LanguageModelSession?
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var waveformTimer: Timer?
    private let dataManager = DataManager.shared
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        requestPermissions()
        loadPersistedData()
    }
    
    // MARK: - Public Methods
    
    func initializeAI() async {
        print("🤖 [ChatStore] initializeAI called")
        do {
            print("🔄 [ChatStore] Creating new LanguageModelSession")
            languageSession = LanguageModelSession()
            
            if messages.isEmpty {
                print("👋 [ChatStore] Adding default Ruby greeting message")
                // Add default Ruby greeting message
                let defaultMessage = ChatMessage(
                    content: "Hey there, what do you want to talk about today?",
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
            currentState = .error("Failed to initialize AI")
        }
    }
    
    func sendMessage(_ text: String) async {
        print("📤 [ChatStore] sendMessage called with text: '\(text)'")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("⚠️ [ChatStore] Message is empty, ignoring")
            return 
        }
        
        print("✅ [ChatStore] Creating user message and adding to chat")
        let userMessage = ChatMessage(content: text, isUser: true, timestamp: Date())
        messages.append(userMessage)
        currentInput = ""
        currentState = .aiThinking
        
        print("🤖 [ChatStore] Starting AI response generation")
        await generateAIResponse(to: text)
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
        stopSpeechRecognition()
        
        if !currentInput.isEmpty {
            print("📤 [ChatStore] Sending transcribed message: '\(currentInput)'")
            Task {
                await sendMessage(currentInput)
            }
        } else {
            print("🚫 [ChatStore] No input to send, returning to active chat")
            currentState = .activeChat
        }
    }
    
    func startNewSession() {
        messages.removeAll()
        streamingContent = ""
        currentInput = ""
        currentSession = nil
        
        // Reset Foundation Models session to clear context
        languageSession = LanguageModelSession()
        currentState = .activeChat
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
            // Add default Ruby greeting message
            let defaultMessage = ChatMessage(
                content: "Hey there, what do you want to talk about today?",
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
    
    // MARK: - Private Methods
    
    private func generateAIResponse(to input: String) async {
        print("🧠 [ChatStore] generateAIResponse started for input: '\(input)'")
        isAITyping = true
        streamingContent = ""
        
        do {
            print("📊 [ChatStore] Analyzing message...")
            // Analyze the input first
            let analysis = try await analyzeMessage(input)
            print("✅ [ChatStore] Message analysis completed: \(analysis)")
            
            // Generate response based on analysis
            if settings.streamingEnabled {
                print("🌊 [ChatStore] Using streaming response mode")
                currentState = .streaming
                await generateStreamingResponse(input: input, analysis: analysis)
            } else {
                print("📝 [ChatStore] Using complete response mode")
                await generateCompleteResponse(input: input, analysis: analysis)
            }
            
        } catch let error as LanguageModelSession.GenerationError {
            // Specific handling for GenerationError types
            switch error {
            case .exceededContextWindowSize(let context):
                lastError = .contextWindowExceeded
                await handleContextWindowExceeded()
                print("Error: Context window size exceeded. \(error.errorDescription). The specific failure reason is:  \(error.failureReason ?? " No failure reason detected..." ). Recovery Suggestion is to: \(error.recoverySuggestion ?? "No recovery suggestion detected")")
//            case .decodingFailure(let context):
//                print("Error: Decoding Failure. \(error.errorDescription). The specific failure reason is:  \(error.failureReason ?? " No failure reason detected..." ). Recovery Suggestion is to: \(error.recoverySuggestion ?? "No recovery suggestion detected")")
            default:
                lastError = .modelUnavailable
                currentState = .error("AI model temporarily unavailable")
                print("An unexpected generation error occurred: \(error.errorDescription). The specific failure reason is:  \(error.failureReason ?? " No failure reason detected..." ). Recovery Suggestion is to: \(error.recoverySuggestion ?? "No recovery suggestion detected")")
            }
        } catch {
            print("❌ [ChatStore] Unknown error occurred with LMS: \(error.localizedDescription)")
            lastError = .modelUnavailable
            currentState = .error("Failed to generate response")
        }
        isAITyping = false
        print("🏁 [ChatStore] generateAIResponse completed")
    }
    
    private func analyzeMessage(_ input: String) async throws -> MessageAnalysis {
        let prompt = """
        Analyze this user message and determine the appropriate response characteristics:
        
        User message: "\(input)"
        
        Consider the conversation context and provide analysis for response generation.
        """
        
        return try await languageSession?.respond(
            to: prompt,
            generating: MessageAnalysis.self
        ).content ?? MessageAnalysis(
            intent: "conversation",
            sentiment: "neutral",
            responseLength: "brief",
            requiresTools: false
        )
    }
    
    private func generateStreamingResponse(input: String, analysis: MessageAnalysis) async {
        let systemPrompt = settings.selectedPersona.systemPrompt
        let fullPrompt = """
        \(systemPrompt)
        
        User intent: \(analysis.intent)
        Sentiment: \(analysis.sentiment)
        Preferred response length: \(analysis.responseLength)
        
        User message: "\(input)"
        
        Provide a helpful response matching the user's needs and the specified persona.
        """
        
        do {
            let stream = languageSession?.streamResponse(
                to: fullPrompt,
                generating: ChatResponse.self
            )
            
            if let stream = stream {
                for try await partial in stream {
                    streamingContent = partial.content ?? "REPLACE THIS DEFAULT VALUE LATER"
                }
                
                // Create final message when streaming completes
                let finalMessage = ChatMessage(
                    content: streamingContent,
                    isUser: false,
                    timestamp: Date(),
                    metadata: ChatMessage.MessageMetadata(
                        processingTime: nil,
                        tokens: streamingContent.split(separator: " ").count,
                        confidence: nil
                    )
                )
                
                messages.append(finalMessage)
                streamingContent = ""
                currentState = .activeChat
            }
        } catch {
            await fallbackToCompleteResponse(input: input, analysis: analysis)
        }
    }
    
    private func generateCompleteResponse(input: String, analysis: MessageAnalysis) async {
        print("💬 [ChatStore] generateCompleteResponse started")
        let systemPrompt = settings.selectedPersona.systemPrompt
        let fullPrompt = """
        \(systemPrompt)
        
        User intent: \(analysis.intent)
        Sentiment: \(analysis.sentiment)
        Preferred response length: \(analysis.responseLength)
        
        User message: "\(input)"
        
        Provide a helpful response matching the user's needs and the specified persona.
        """
        
        print("🔍 [ChatStore] Full prompt: \(fullPrompt)")
        
        do {
            let startTime = Date()
            print("⏰ [ChatStore] Sending request to language model...")
            let response = try await languageSession?.respond(
                to: fullPrompt,
                generating: ChatResponse.self
            )
            let processingTime = Date().timeIntervalSince(startTime)
            print("⏱️ [ChatStore] Response received in \(processingTime) seconds")
            
            if let response = response {
                print("✅ [ChatStore] Response content: '\(response.content)'")
                let aiMessage = ChatMessage(
                    content: response.content.content,
                    isUser: false,
                    timestamp: Date(),
                    metadata: ChatMessage.MessageMetadata(
                        processingTime: processingTime,
                        tokens: response.content.content.split(separator: " ").count,
                        confidence: response.content.confidence
                    )
                )
                
                messages.append(aiMessage)
                currentState = .activeChat
                print("✅ [ChatStore] AI message added to chat, returning to active state")
            } else {
                print("❌ [ChatStore] Response was nil")
                lastError = .modelUnavailable
                currentState = .error("No response from AI")
            }
        } catch {
            print("❌ [ChatStore] Error in generateCompleteResponse: \(error.localizedDescription)")
            lastError = .modelUnavailable
            currentState = .error("Failed to generate response")
        }
    }
    
    private func fallbackToCompleteResponse(input: String, analysis: MessageAnalysis) async {
        currentState = .aiThinking
        await generateCompleteResponse(input: input, analysis: analysis)
    }
    
    private func handleContextWindowExceeded() async {
        // Summarize older messages and start fresh session
        let recentMessages = Array(messages.suffix(5))
        messages = recentMessages
        languageSession = LanguageModelSession()
        
        // Inform user about context reset
        let systemMessage = ChatMessage(
            content: "Conversation context was reset to manage memory. Recent messages have been preserved.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(systemMessage)
        currentState = .activeChat
    }
    
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
              speechRecognizer.isAvailable else {
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
        
        Task {
            do {
                try dataManager.saveSession(session)
            } catch {
                print("Failed to save session: \(error)")
                lastError = .saveFailed
            }
        }
    }
    
    func saveSettings() {
        Task {
            do {
                try dataManager.saveSettings(settings)
            } catch {
                print("Failed to save settings: \(error)")
                lastError = .saveFailed
            }
        }
    }
    
    func loadSession(_ session: ConversationSession) async {
        currentSession = session
        messages = session.messages
        settings.selectedPersona = session.persona
        
        if messages.isEmpty {
            // Add default Ruby greeting message
            let defaultMessage = ChatMessage(
                content: "Hey there, what do you want to talk about today?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(defaultMessage)
        }
        currentState = .activeChat
        
        // Reinitialize language session with new persona
        languageSession = LanguageModelSession()
    }
    
    func deleteSession(_ session: ConversationSession) {
        Task {
            do {
                try dataManager.deleteSession(withId: session.id)
                savedSessions.removeAll { $0.id == session.id }
                
                // If this was the current session, start a new one
                if currentSession?.id == session.id {
                    startNewSession()
                }
            } catch {
                print("Failed to delete session: \(error)")
                lastError = .saveFailed
            }
        }
    }
    
    func createSessionFromCurrentMessages() {
        guard !messages.isEmpty else { return }
        
        let session = ConversationSession(
            title: generateSessionTitle(),
            createdAt: messages.first?.timestamp ?? Date(),
            lastModified: Date(),
            messages: messages,
            persona: settings.selectedPersona
        )
        
        currentSession = session
        savedSessions.insert(session, at: 0)
        saveCurrentSession()
    }
    
    private func generateSessionTitle() -> String {
        if let firstMessage = messages.first(where: { $0.isUser }) {
            let words = firstMessage.content.split(separator: " ").prefix(5)
            return String(words.joined(separator: " "))
        }
        return "New Conversation"
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
        Task {
            do {
                try dataManager.importData(data)
                await loadPersistedData() // Reload after import
            } catch {
                print("Failed to import data: \(error)")
                lastError = .loadFailed
            }
        }
    }
}
