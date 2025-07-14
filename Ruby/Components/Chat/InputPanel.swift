//
//  InputPanel.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

// MARK: - Input Panel

@available(iOS 26.0, *)
struct InputPanel: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var messageText: String
    @FocusState.Binding var isTextFieldFocused: Bool
    @State private var isVoiceRecording = false
    @State private var realTimeTranscription = ""

    var body: some View {

        VStack(spacing: 12) {
            MessageInputField(
                messageText: $messageText,
                isVoiceRecording: isVoiceRecording,
                isTextFieldFocused: $isTextFieldFocused,
                shouldShowMicButton: shouldShowMicButton,
                canSendMessage: canSendMessage,
                sendMessage: sendMessage,
                startVoiceRecording: startVoiceRecordingAction,
                stopVoiceRecording: stopVoiceRecordingAction
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onChange(of: chatStore.currentState) { _, newState in
            isVoiceRecording = (newState == .voiceListening)
        }
        .onChange(of: chatStore.isRecording) { _, recording in
            isVoiceRecording = recording
            if !recording {
                realTimeTranscription = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VoiceTranscriptionUpdate"))) { notification in
            if let transcription = notification.object as? String {
                realTimeTranscription = transcription
                // Update the message text with real-time transcription during recording
                if isVoiceRecording {
                    messageText = transcription
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var shouldShowMicButton: Bool {
        // If currently recording, always show mic button (in recording state)
        if isVoiceRecording {
            return true
        }
        
        // If not recording, show mic button only when text field is not focused and empty
        return !isTextFieldFocused
            && messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    private var canSendMessage: Bool {
        return !messageText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Actions
    private func startVoiceRecordingAction() {
        print("▶️ [InputPanel] Starting voice recording")
        isTextFieldFocused = false
        chatStore.startVoiceRecording()
    }
    
    private func stopVoiceRecordingAction() {
        print("🚫 [InputPanel] Stopping voice recording")
        chatStore.stopVoiceRecording()
        // Focus text field after stopping recording so user can edit/send
        isTextFieldFocused = true
    }

    private func sendMessage() {
        print("📤 [InputPanel] Send button tapped with text: '\(messageText)'")
        guard canSendMessage else {
            print("⚠️ [InputPanel] Cannot send empty message")
            return
        }

        let textToSend = messageText
        messageText = ""
        isTextFieldFocused = false

        Task {
            await chatStore.sendMessage(textToSend)
        }
    }
}

