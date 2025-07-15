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
    private var titleGenerationSession: LanguageModelSession?
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var waveformTimer: Timer?
    private let dataManager = DataManager.shared
    
    // MARK: - Enhanced Services
    private let personaContextService = PersonaContextService()
    private let intentToolManager = IntentToolManager.shared
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        requestPermissions()
        loadPersistedData()
        
        // Connect this ChatStore instance to the shared managers
        ChatStoreManager.shared.chatStore = self
        SettingsManager.shared.chatStore = self
        
        // Set up automatic saving when app goes to background
        setupBackgroundSaving()
    }
    
    // MARK: - Public Methods
    
    func initializeAI() async {
        print("🤖 [ChatStore] initializeAI called")
        do {
            print("🔄 [ChatStore] Creating new LanguageModelSession")
            languageSession = LanguageModelSession()
            
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
    
    func sendMessage(_ text: String) async {
        print("📤 [ChatStore] sendMessage called with text: '\(text)'")
        print("📤 [ChatStore] Current message count before: \(messages.count)")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("⚠️ [ChatStore] Message is empty, ignoring")
            return 
        }
        
        // Check if we're already processing a message to prevent duplicates
        guard currentState != .aiThinking && currentState != .streaming else {
            print("⚠️ [ChatStore] Already processing a message, ignoring duplicate request")
            return
        }
        
        print("✅ [ChatStore] Creating user message and adding to chat")
        let userMessage = ChatMessage(content: text, isUser: true, timestamp: Date())
        messages.append(userMessage)
        currentInput = ""
        currentState = .aiThinking
        
        print("📤 [ChatStore] Message count after adding user message: \(messages.count)")
        
        // Immediately save user message to prevent data loss
        if let session = currentSession {
            var updatedSession = session
            updatedSession.messages = messages
            updatedSession.lastModified = Date()
            currentSession = updatedSession
            saveCurrentSessionSynchronously()
        }
        
        // Auto-create session if this is the first user message
        if currentSession == nil && messages.filter({ $0.isUser }).count == 1 {
            createSessionFromCurrentMessages()
            // Start async title generation in background after session creation
            Task.detached { [weak self] in
                await self?.generateAndUpdateTitleAsync()
            }
        }
        
        print("🤖 [ChatStore] Starting AI response generation")
        await generateAIResponse(to: text)
        
        print("📤 [ChatStore] Final message count: \(messages.count)")
        
        // Update session after each interaction - do this synchronously for better persistence
        if let session = currentSession {
            var updatedSession = session
            updatedSession.messages = messages
            updatedSession.lastModified = Date()
            currentSession = updatedSession
            
            // Save immediately to prevent data loss
            saveCurrentSessionSynchronously()
        }
    }
    
    func startVoiceRecording() {
        print("🎤 [ChatStore] startVoiceRecording called")
        guard !isRecording else { 
            print("⚠️ [ChatStore] Already recording, ignoring")
            return 
        }
        
        print("▶️ [ChatStore] Starting voice recording - changing state to voiceListening")
        self.currentState = .voiceListening
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
        currentState = .activeChat  // Always reset to active chat first
        stopSpeechRecognition()
        
        // Don't automatically send the message - let user decide
        print("✅ [ChatStore] Voice recording stopped, transcribed text available for user to send manually")
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
            Task.detached { [weak self] in
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
    
    func regenerateSessionTitle() {
        // Start async title generation
        Task.detached { [weak self] in
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
        // Initialize title generation session if needed
        if titleGenerationSession == nil {
            titleGenerationSession = LanguageModelSession()
        }
        
        guard let titleSession = titleGenerationSession else {
            print("❌ [ChatStore] No title generation session available")
            return generateFallbackTitle()
        }
        
        // Find messages for context
        let userMessages = messages.filter({ $0.isUser }).prefix(3)
        let aiMessages = messages.filter({ !$0.isUser }).prefix(3)
        
        guard !userMessages.isEmpty else {
            return "New Conversation"
        }
        
        // Create conversation context
        var conversationContext = ""
        let allMessages = (Array(userMessages) + Array(aiMessages)).sorted { $0.timestamp < $1.timestamp }
        
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
            let titleResponse = try await titleSession.respond(
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
        let userMessages = messages.filter({ $0.isUser }).prefix(2)
        
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
                // Keep thinking state until streaming actually starts
                await generateStreamingResponse(input: input, analysis: analysis)
            } else {
                print("📝 [ChatStore] Using complete response mode")
                await generateCompleteResponse(input: input, analysis: analysis)
            }
            
        } catch let error as LanguageModelSession.GenerationError {
            // Comprehensive handling for all GenerationError types
            let chatError: ChatError
            
            switch error {
            case .exceededContextWindowSize(_):
                chatError = .contextWindowExceeded
                await handleContextWindowExceeded()
                print("Error: Context window exceeded - \(error.errorDescription ?? "No description")")
                
            case .assetsUnavailable(_):
                chatError = .assetsUnavailable
                print("Error: Assets unavailable - \(error.errorDescription ?? "No description")")
                
            case .decodingFailure(_):
                chatError = .decodingFailure
                print("Error: Decoding failure - \(error.errorDescription ?? "No description")")
                
            case .guardrailViolation(_):
                chatError = .guardrailViolation
                print("Error: Guardrail violation - \(error.errorDescription ?? "No description")")
                
            case .unsupportedGuide(_):
                chatError = .unsupportedGuide
                print("Error: Unsupported guide - \(error.errorDescription ?? "No description")")
                
            default:
                chatError = .modelUnavailable
                print("Error: Unexpected generation error - \(error.errorDescription ?? "No description")")
            }
            
            // Generate user-friendly error message using AI
            await handleErrorWithAIMessage(chatError)
            
        } catch {
            print("❌ [ChatStore] Unknown error occurred: \(error.localizedDescription)")
            await handleErrorWithAIMessage(.modelUnavailable)
        }
        isAITyping = false
        print("🏁 [ChatStore] generateAIResponse completed")
    }
    
    private func analyzeMessage(_ input: String) async throws -> MessageAnalysis {
        print("🔍 [ChatStore] Analyzing message: '\(input)'")
        
        let availableTools = IntentToolManager.availableTools.map { tool in
            "- \(tool.name): \(tool.description)"
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze this user message and determine if it requires tool usage or regular conversation:
        
        User message: "\(input)"
        
        Available tools:
        \(availableTools)
        
        Determine:
        1. Intent: question, request, conversation, command, greeting
        2. Sentiment: positive, neutral, negative
        3. Response length needed: brief, detailed, comprehensive
        4. Whether this requires tool usage (requiresTools: true/false)
        """
        
        let analysis = try await languageSession?.respond(
            to: prompt,
            generating: MessageAnalysis.self
        ).content ?? MessageAnalysis(
            intent: "conversation",
            sentiment: "neutral",
            responseLength: "brief",
            requiresTools: false
        )
        
        print("📊 [ChatStore] Message analysis result:")
        print("📊 [ChatStore] - Intent: \(analysis.intent)")
        print("📊 [ChatStore] - Sentiment: \(analysis.sentiment)")
        print("📊 [ChatStore] - Response Length: \(analysis.responseLength)")
        print("📊 [ChatStore] - Requires Tools: \(analysis.requiresTools)")
        
        return analysis
    }
    
    private func generateStreamingResponse(input: String, analysis: MessageAnalysis) async {
        print("🌊 [ChatStore] generateStreamingResponse started")
        
        // Use the same enhanced prompt as complete response for consistency
        let fullPrompt = await generateEnhancedPrompt(for: input, analysis: analysis)
        
        do {
            let startTime = Date()
            print("⏰ [ChatStore] Starting streaming request...")
            
            let stream = languageSession?.streamResponse(
                to: fullPrompt,
                generating: ChatResponse.self
            )
            
            if let stream = stream {
                print("🌊 [ChatStore] Streaming started successfully")
                var hasStartedStreaming = false
                for try await partial in stream {
                    // Only switch to streaming state once we get first content
                    if !hasStartedStreaming && !(partial.content?.isEmpty ?? true) {
                        currentState = .streaming
                        hasStartedStreaming = true
                        print("🌊 [ChatStore] First token received, switching to streaming state")
                    }
                    streamingContent = partial.content ?? ""
                }
                
                let processingTime = Date().timeIntervalSince(startTime)
                print("✅ [ChatStore] Streaming completed in \(processingTime) seconds")
                
                // Create final message when streaming completes
                let finalMessage = ChatMessage(
                    content: streamingContent,
                    isUser: false,
                    timestamp: Date(),
                    metadata: ChatMessage.MessageMetadata(
                        processingTime: processingTime,
                        tokens: streamingContent.split(separator: " ").count,
                        confidence: nil
                    )
                )
                
                messages.append(finalMessage)
                print("✅ [ChatStore] Streaming message added to chat")
                streamingContent = ""
                currentState = .activeChat
                
                // Immediately save the message to prevent data loss
                if let session = currentSession {
                    var updatedSession = session
                    updatedSession.messages = messages
                    updatedSession.lastModified = Date()
                    currentSession = updatedSession
                    saveCurrentSessionSynchronously()
                }
            } else {
                print("❌ [ChatStore] Streaming session was nil")
                await handleErrorWithAIMessage(.modelUnavailable)
            }
        } catch {
            print("❌ [ChatStore] Streaming failed: \(error.localizedDescription)")
            await handleErrorWithAIMessage(.modelUnavailable)
        }
    }
    
    private func generateCompleteResponse(input: String, analysis: MessageAnalysis) async {
        print("💬 [ChatStore] ================================")
        print("💬 [ChatStore] GENERATE COMPLETE RESPONSE STARTED")
        print("💬 [ChatStore] Input: '\(input)'")
        print("💬 [ChatStore] Current State: \(currentState)")
        print("💬 [ChatStore] Message Count: \(messages.count)")
        print("💬 [ChatStore] ================================")
        
        // Check if this requires tool calling first
        if analysis.requiresTools {
            print("🔧 [ChatStore] Redirecting to tool calling due to requiresTools=true")
            await handleToolCallingRequest(input: input, analysis: analysis)
            return
        }
        
        print("📝 [ChatStore] Proceeding with normal response generation")
        let fullPrompt = await generateEnhancedPrompt(for: input, analysis: analysis)
        
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
                await handleErrorWithAIMessage(.modelUnavailable)
            }
        } catch {
            print("❌ [ChatStore] Error in generateCompleteResponse: \(error.localizedDescription)")
            await handleErrorWithAIMessage(.modelUnavailable)
        }
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
    
    // MARK: - Error Handling with AI Messages
    
    private func handleErrorWithAIMessage(_ error: ChatError) async {
        print("🤖 [ChatStore] Generating user-friendly error message for: \(error)")
        
        // Set error state but continue processing
        lastError = error
        
        // For critical errors that need immediate handling, handle them first
        if error == .contextWindowExceeded {
            return // handleContextWindowExceeded already called
        }
        
        // Generate user-friendly error message using AI
        guard let session = languageSession else {
            // Fallback if AI session is not available
            addFallbackErrorMessage(for: error)
            currentState = .activeChat
            return
        }
        
        do {
            let errorContext = """
            Technical Error: \(error.errorDescription ?? "Unknown error occurred")
            
            Your task: Convert this technical error into a warm, conversational response that:
            1. Explains to the user why you can't fulfill their request in a friendly way
            2. Offers a helpful suggestion if appropriate
            3. Maintains a positive, encouraging tone
            4. Sounds like you're speaking directly to them as your AI assistant
            
            Examples:
            - For unsafe content: "I can't help with that kind of content, but I'd be happy to chat about something else!"
            - For technical issues: "Oops, I'm having a small technical hiccup. Mind trying that again?"
            - For unavailable features: "That feature isn't available right now, but here's what I can help with instead..."
            """
            
            let userFriendlyError = try await session.respond(
                to: errorContext,
                generating: UserFriendlyErrorMessage.self
            )
//            try await session.GenerationOptions(prompt:
//                prompt: errorContext,
//                options: LanguageModelSession.GenerationOptions(
//                    generationMode: .complete,
//                    outputSchema: .type(UserFriendlyErrorMessage.self)
//                )
//            )
            
            // Add the AI-generated error message as a chat message
            let errorMessage = ChatMessage(
                content: userFriendlyError.content.message + (userFriendlyError.content.suggestion.map { "\n\n\($0)" } ?? ""),
                isUser: false,
                timestamp: Date(),
                metadata: ChatMessage.MessageMetadata(
                    processingTime: nil,
                    tokens: nil,
                    confidence: 0.9
                )
            )
            
            messages.append(errorMessage)
            currentState = .activeChat
            print("✅ [ChatStore] Added user-friendly error message to chat")
            
        } catch {
            print("❌ [ChatStore] Failed to generate user-friendly error message: \(error.localizedDescription)")
            // Fallback to standard error message
            addFallbackErrorMessage(for: .assetsUnavailable)
            currentState = .activeChat
        }
    }
    
    private func addFallbackErrorMessage(for error: ChatError) {
        let fallbackMessage: String
        
        switch error {
        case .guardrailViolation:
            fallbackMessage = "I can't help with that kind of content, but I'd be happy to chat about something else! What else would you like to talk about?"
        case .contextWindowExceeded:
            fallbackMessage = "Our conversation has gotten quite long! I'll need to start fresh, but feel free to continue where we left off."
        case .assetsUnavailable:
            fallbackMessage = "I'm having trouble accessing some resources right now. Could you try again in a moment?"
        case .decodingFailure:
            fallbackMessage = "Something got a bit scrambled on my end. Mind trying that again?"
        case .unsupportedGuide:
            fallbackMessage = "I'm not quite sure how to format that response. Could you try asking in a different way?"
        default:
            fallbackMessage = "I'm having a small technical hiccup. Could you try that again? I'm here and ready to help!"
        }
        
        let errorMessage = ChatMessage(
            content: fallbackMessage,
            isUser: false,
            timestamp: Date()
        )
        
        messages.append(errorMessage)
        print("✅ [ChatStore] Added fallback error message to chat")
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
        Task {
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
        saveCurrentSession()
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
    
    func clearAllData() {
        Task {
            do {
                try dataManager.clearAllData()
                // Reset in-memory state
                savedSessions.removeAll()
                currentSession = nil
                startNewSession()
                settings = ChatSettings.default
            } catch {
                print("Failed to clear data: \(error)")
                lastError = .saveFailed
            }
        }
    }
    
    // MARK: - Enhanced LLM Integration Methods
    
    private func generateEnhancedPrompt(for input: String, analysis: MessageAnalysis) async -> String {
        print("🧾 [ChatStore] Generating enhanced prompt for: '\(input)'")
        
        let basePrompt = settings.selectedPersona.systemPrompt
        
        // Fetch relevant context for the persona with user input for better relevance
        let contextItems = await personaContextService.getContextForPersona(settings.selectedPersona, userInput: input)
        
        var enhancedPrompt = basePrompt
        
        if !contextItems.isEmpty {
            print("📚 [ChatStore] Adding \(contextItems.count) context items for persona: \(settings.selectedPersona)")
            enhancedPrompt += "\n\nRelevant context for inspiration:\n"
            for item in contextItems {
                enhancedPrompt += "• \(item.content) - \(item.source)\n"
            }
            enhancedPrompt += "\nUse this context subtly to enrich your response when appropriate, but don't force it if it doesn't fit naturally.\n"
        } else {
            print("📚 [ChatStore] No context items available for persona: \(settings.selectedPersona)")
        }
        
        enhancedPrompt += """
        
        User intent: \(analysis.intent)
        Sentiment: \(analysis.sentiment)
        Preferred response length: \(analysis.responseLength)
        
        User message: "\(input)"
        
        Provide a helpful response matching the user's needs and the specified persona.
        """
        
        print("📝 [ChatStore] Enhanced prompt length: \(enhancedPrompt.count) characters")
        
        return enhancedPrompt
    }
    
    private func handleToolCallingRequest(input: String, analysis: MessageAnalysis) async {
        print("🔧 [ChatStore] ================================")
        print("🔧 [ChatStore] TOOL CALLING REQUEST INITIATED")
        print("🔧 [ChatStore] Input: '\(input)'")
        print("🔧 [ChatStore] Analysis: \(analysis)")
        print("🔧 [ChatStore] Current State: \(currentState)")
        print("🔧 [ChatStore] ================================")
        
        // Analyze the input to determine which tool to call
        let toolName = await identifyToolFromInput(input)
        let parameters = await extractToolParameters(from: input, toolName: toolName)
        
        print("🔧 [ChatStore] Identified Tool: '\(toolName)'")
        print("🔧 [ChatStore] Tool Parameters: \(parameters)")
        
        do {
            let result = try await intentToolManager.executeIntent(toolName: toolName, parameters: parameters)
            
            print("✅ [ChatStore] Tool execution successful: \(result)")
            
            // Add system message showing the action was completed
            let systemMessage = ChatMessage(
                content: result,
                isUser: false,
                timestamp: Date()
            )
            messages.append(systemMessage)
            currentState = .activeChat
            
            print("✅ [ChatStore] Tool calling completed successfully")
            
        } catch {
            print("❌ [ChatStore] Tool execution failed: \(error.localizedDescription)")
            print("❌ [ChatStore] Error details: \(error)")
            
            // Handle tool execution errors
            let errorMessage = ChatMessage(
                content: "I tried to perform that action, but encountered an issue: \(error.localizedDescription). Please try again or ask me to do something else.",
                isUser: false,
                timestamp: Date()
            )
            messages.append(errorMessage)
            currentState = .activeChat
        }
        
        print("🔧 [ChatStore] Tool calling request completed")
    }
    
    private func identifyToolFromInput(_ input: String) async -> String {
        let lowercasedInput = input.lowercased()
        
        // Simple pattern matching for common requests
        if lowercasedInput.contains("go to") || lowercasedInput.contains("switch to") || lowercasedInput.contains("navigate to") {
            if lowercasedInput.contains("chat") {
                return "navigate_to_tab"
            } else if lowercasedInput.contains("home") {
                return "navigate_to_tab"
            }
        }
        
        if lowercasedInput.contains("new chat") || lowercasedInput.contains("start conversation") {
            return "start_new_chat"
        }
        
        if lowercasedInput.contains("change persona") || lowercasedInput.contains("switch to") {
            return "change_persona"
        }
        
        if lowercasedInput.contains("voice input") || lowercasedInput.contains("record") {
            return "start_voice_input"
        }
        
        // Default fallback
        return "navigate_to_tab"
    }
    
    private func extractToolParameters(from input: String, toolName: String) async -> [String: Any] {
        let lowercasedInput = input.lowercased()
        
        switch toolName {
        case "navigate_to_tab":
            if lowercasedInput.contains("chat") {
                return ["tab": "Chat"]
            } else {
                return ["tab": "Home"]
            }
        case "change_persona":
            if lowercasedInput.contains("therapist") {
                return ["persona": "Welcoming Therapist"]
            } else if lowercasedInput.contains("professor") {
                return ["persona": "Distinguished Professor"]
            } else if lowercasedInput.contains("tech") {
                return ["persona": "Tech Lead"]
            } else if lowercasedInput.contains("musician") {
                return ["persona": "World-Class Musician"]
            } else if lowercasedInput.contains("comedian") {
                return ["persona": "Wise Comedian"]
            }
            return ["persona": "Welcoming Therapist"]
        default:
            return [:]
        }
    }
    
    // MARK: - Public Tool Calling Interface
    
    func handleToolCall(toolName: String, parameters: [String: Any]) async {
        await handleToolCallingRequest(input: "Tool call: \(toolName)", analysis: MessageAnalysis(intent: "command", sentiment: "neutral", responseLength: "brief", requiresTools: true))
    }
    
    // MARK: - Background Saving
    
    private func setupBackgroundSaving() {
        // Save when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 [ChatStore] App going to background, saving session...")
            self?.saveCurrentSessionSynchronously()
        }
        
        // Save when app terminates
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📱 [ChatStore] App terminating, saving session...")
            self?.saveCurrentSessionSynchronously()
        }
    }
}
