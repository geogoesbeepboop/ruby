//
//  MessageInputField.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct MessageInputField: View {
    @Binding var messageText: String
    let isVoiceRecording: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let shouldShowMicButton: Bool
    let canSendMessage: Bool

    let sendMessage: () -> Void
    let startVoiceRecording: () -> Void
    let stopVoiceRecording: () -> Void

    @State private var textHeight: CGFloat = 44
    private let minHeight: CGFloat = 44
    private let maxHeight: CGFloat = 100

    var body: some View {
        ZStack {
            // Main text field container with unified background
            HStack(spacing: 0) {
                // Text field with proper containment for select all bubble
                ZStack(alignment: .topLeading) {
                    TextField(
                        isVoiceRecording ? "Listening..." : "Ask anything",
                        text: $messageText,
                        axis: .vertical
                    )
                    .focused($isTextFieldFocused)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .lineLimit(nil)
                    .textFieldStyle(PlainTextFieldStyle())
                    .submitLabel(.send)
                    .onSubmit {
                        if !messageText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {
                            sendMessage()
                        }
                    }
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .frame(minHeight: minHeight - 24, maxHeight: maxHeight - 24)
                    .padding(.leading, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 44)
                    .clipped() // Ensure select all bubble stays within bounds
                    .contentShape(Rectangle()) // Proper hit testing
                    
                    // Invisible overlay to ensure proper text positioning
                    if messageText.isEmpty {
                        HStack {
                            Text("Ask anything")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.leading, 16)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
            .background(
                // Hidden text for height calculation
                GeometryReader { geometry in
                    Text(messageText.isEmpty ? " " : messageText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .onAppear {
                            updateHeight(from: geometry)
                        }
                        .onChange(of: messageText) { _, _ in
                            updateHeight(from: geometry)
                        }
                        .opacity(0)
                }
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: min(textHeight / 2, 22))
            )
            
            // Integrated button on the right
            HStack {
                Spacer()
                if shouldShowMicButton {
                    IntegratedMicButton(
                        isRecording: isVoiceRecording,
                        startVoiceRecording: startVoiceRecording,
                        stopVoiceRecording: stopVoiceRecording
                    )
                } else {
                    IntegratedSendButton(
                        canSendMessage: canSendMessage,
                        sendMessage: sendMessage
                    )
                }
            }
            .padding(.trailing, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func updateHeight(from geometry: GeometryProxy) {
        let newHeight = max(minHeight, min(maxHeight, geometry.size.height))
        if abs(textHeight - newHeight) > 1 {
            withAnimation(.easeOut(duration: 0.15)) {
                textHeight = newHeight
            }
        }
    }
}
