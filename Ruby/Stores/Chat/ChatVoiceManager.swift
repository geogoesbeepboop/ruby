import Foundation
import SwiftUI
import AVFoundation
import Speech
import os.log

@Observable
@MainActor
final class ChatVoiceManager {
    // MARK: - Properties
    
    var isRecording: Bool = false
    var currentTranscription: String = ""
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var voiceInputTimer: Timer?
    
    private let logger = Logger(subsystem: "com.ruby.app", category: "ChatVoiceManager")
    
    // MARK: - Initialization
    
    init() {
        logger.info("🔧 [ChatVoiceManager] Initializing ChatVoiceManager")
    }
    
    // MARK: - Voice Recording
    
    func startVoiceRecording() async throws {
        logger.info("🎤 [ChatVoiceManager] Starting voice recording")
        
        guard !isRecording else {
            logger.warning("⚠️ [ChatVoiceManager] Voice recording already in progress")
            return
        }
        
        // Request permissions
        let hasPermission = await requestSpeechPermissions()
        
        if hasPermission {
            try setupVoiceRecording()
        } else {
            logger.error("❌ [ChatVoiceManager] Speech recognition permission denied")
            throw ChatError.other
        }
    }
    
    func stopVoiceRecording() -> String {
        logger.info("🛑 [ChatVoiceManager] Stopping voice recording")
        
        guard isRecording else {
            logger.warning("⚠️ [ChatVoiceManager] No active voice recording to stop")
            return ""
        }
        
        let finalTranscription = currentTranscription
        cleanupVoiceRecording()
        return finalTranscription
    }
    
    // MARK: - Private Methods
    
    private func requestSpeechPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func setupVoiceRecording() throws {
        logger.info("🔧 [ChatVoiceManager] Setting up voice recording session")
        
        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer()
        
        guard let audioEngine = audioEngine,
              let speechRecognizer = speechRecognizer else {
            logger.error("❌ [ChatVoiceManager] Failed to initialize audio components")
            throw ChatError.other
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            logger.error("❌ [ChatVoiceManager] Failed to create recognition request")
            throw ChatError.other
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    self.currentTranscription = transcription
                    
                    // Post transcription update notification
                    NotificationCenter.default.post(
                        name: NSNotification.Name("VoiceTranscriptionUpdate"),
                        object: transcription
                    )
                    
                    self.logger.debug("🗣️ [ChatVoiceManager] Voice transcription: '\(transcription)'")
                }
                
                if let error = error {
                    self.logger.error("❌ [ChatVoiceManager] Speech recognition error: \(error.localizedDescription)")
                    self.cleanupVoiceRecording()
                }
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        currentTranscription = ""
        
        // Auto-stop after 30 seconds
        voiceInputTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                _ = self?.stopVoiceRecording()
            }
        }
        
        logger.info("✅ [ChatVoiceManager] Voice recording started successfully")
    }
    
    private func cleanupVoiceRecording() {
        logger.info("🧹 [ChatVoiceManager] Cleaning up voice recording")
        
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
        currentTranscription = ""
        
        logger.info("✅ [ChatVoiceManager] Voice recording cleanup completed")
    }
    
    func shutdown() {
        logger.info("🔥 [ChatVoiceManager] ChatVoiceManager deinitializing")
        cleanupVoiceRecording()
    }
}
