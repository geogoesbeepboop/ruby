//
//  ChatBubble.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

// MARK: - Unified Chat Bubble Component

@available(iOS 26.0, *)
struct UnifiedChatBubble: View {
    let message: ChatMessage
    let onLongPress: (UUID) -> Void
    let enhanced: Bool
    @State private var showMetadata = false
    @Environment(ChatCoordinator.self) private var chatCoordinator
    
    private let maxBubbleWidth = UIScreen.main.bounds.width * 0.75
    
    // Computed property to show streaming content for empty AI messages
    private var displayContent: String {
        // Show streaming content for empty AI messages during streaming
        if !message.isUser && message.content.isEmpty,
           let streamingContent = chatCoordinator.aiManager.streamingContent,
           !streamingContent.isEmpty {
            return streamingContent
        }
        return message.content
    }
    
    // Check if this is an actively streaming message
    private var isActivelyStreaming: Bool {
        return !message.isUser && 
               message.content.isEmpty && 
               chatCoordinator.uiManager.currentState == .streaming &&
               (chatCoordinator.aiManager.streamingContent?.isEmpty ?? true)
    }
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser { 
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                // Main message bubble
                messageContent
                    .frame(maxWidth: maxBubbleWidth, alignment: message.isUser ? .trailing : .leading)
                
                // Enhanced metadata display
                if enhanced, let metadata = message.metadata, showMetadata {
                    MessageMetadataView(metadata: metadata)
                        .frame(maxWidth: maxBubbleWidth, alignment: .leading)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Bottom row with metadata toggle, confidence, and timestamp
                HStack {
                    if enhanced && !message.isUser {
                        metadataToggleButton
                        
                        if let metadata = message.metadata, let confidence = metadata.confidence {
                            ConfidenceIndicator(confidence: confidence)
                        }
                    }
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                .frame(maxWidth: maxBubbleWidth)
                
                // Reactions
                if !message.reactions.isEmpty {
                    MessageReactionsView(reactions: message.reactions)
                        .frame(maxWidth: maxBubbleWidth, alignment: message.isUser ? .trailing : .leading)
                }
            }
            
            if !message.isUser { 
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMetadata)
    }
    
    private var messageContent: some View {
        GlassEffectContainer(
            cornerRadius: 18,
            blurRadius: 8,
            opacity: message.isUser ? 0.6 : 0.2
        ) {
            HStack(alignment: .top) {
                if displayContent.isEmpty && isActivelyStreaming {
                    // Show typing indicator for empty streaming messages
                    TypingIndicator()
                } else {
                    Text(displayContent)
                        .contentTransition(.opacity)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .animation(.easeInOut(duration: 0.3), value: displayContent)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background {
            if message.isUser {
                // Dark purple for user messages
                LinearGradient(
                    colors: [
                        Color.brandSecondary.opacity(0.8),
                        Color.brandSecondary.opacity(0.6),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                // Dark gray for AI messages
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.2),
                        Color.primary.opacity(0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .contextMenu {
            MessageContextMenuContent(message: message)
        }
        .onLongPressGesture {
            onLongPress(message.id)
        }
    }
    
    private var metadataToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showMetadata.toggle()
            }
        }) {
            Image(systemName: showMetadata ? "info.circle.fill" : "info.circle")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Legacy ChatBubble (Generic ViewBuilder)

struct ChatBubble<Content: View>: View {
    let content: Content
    let isUser: Bool
    let timestamp: Date
    
    private let maxBubbleWidth = UIScreen.main.bounds.width * 0.75

    init(isUser: Bool, timestamp: Date, @ViewBuilder content: () -> Content) {
        self.isUser = isUser
        self.timestamp = timestamp
        self.content = content()
    }

    var body: some View {
        HStack {
            if isUser { 
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                GlassEffectContainer(
                    cornerRadius: 18,
                    blurRadius: 8,
                    opacity: isUser ? 0.6 : 0.2
                ) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background {
                    if isUser {
                        // Dark purple for user messages
                        LinearGradient(
                            colors: [
                                Color.brandSecondary.opacity(0.8),
                                Color.brandSecondary.opacity(0.6),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        // Dark gray for AI messages
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.2),
                                Color.primary.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .frame(maxWidth: maxBubbleWidth, alignment: isUser ? .trailing : .leading)

                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { 
                Spacer(minLength: UIScreen.main.bounds.width * 0.25)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Supporting Components

@available(iOS 26.0, *)
struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Previews
@available(iOS 26.0, *)
#Preview("Typing Indicator") {
    ScrollView {
        VStack(spacing: 16) {
            TypingIndicator()
        }
    }
}

@available(iOS 26.0, *)
#Preview("Unified Chat Bubbles") {
    ScrollView {
        VStack(spacing: 16) {
            UnifiedChatBubble(
                message: ChatMessage(
                    content: "This is an AI message with enhanced metadata and confidence indicators.",
                    isUser: false,
                    timestamp: Date(),
                    metadata: .init(
                        processingTime: 1.23,
                        tokens: 45,
                        confidence: 0.87
                    )
                ),
                onLongPress: { _ in },
                enhanced: true
            )
            
            UnifiedChatBubble(
                message: ChatMessage(
                    content: "This is a user message that should be aligned to the right with proper width constraints.",
                    isUser: true,
                    timestamp: Date()
                ),
                onLongPress: { _ in },
                enhanced: false
            )
            
            UnifiedChatBubble(
                message: ChatMessage(
                    content: "Simple AI message without enhanced features enabled.",
                    isUser: false,
                    timestamp: Date()
                ),
                onLongPress: { _ in },
                enhanced: false
            )
        }
        .padding()
    }
}

@available(iOS 26.0, *)
#Preview("Legacy Chat Bubble") {
    ChatBubble(isUser: false, timestamp: Date()) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}

