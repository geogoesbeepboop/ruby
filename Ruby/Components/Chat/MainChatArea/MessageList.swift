//
//  MessageList.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct MessagesList: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @Binding var selectedMessageId: UUID?
    @Binding var showingReactionPicker: Bool
    let isTextFieldFocused: Bool

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                let sortedMessages = chatCoordinator.uiManager.messages.sorted {
                    $0.timestamp < $1.timestamp
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedMessages) { message in
                        // Use unified chat bubble with enhanced features for AI messages
                        UnifiedChatBubble(
                            message: message,
                            onLongPress: { messageId in
                                selectedMessageId = messageId
                                showingReactionPicker = true
                            },
                            enhanced: !message.isUser // Enhanced features for AI messages only
                        )
                        .id(message.id)
                    }

                    // Enhanced streaming coordinator that shows appropriate views
//                    if chatCoordinator.uiManager.currentState == .streaming {
//                        StreamingCoordinator()
//                    }
                    Color.clear.frame(height: 16).id("bottom_padding")
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .onChange(of: chatCoordinator.uiManager.messages.count) { _, _ in
                // Always scroll when new messages arrive, with proper timing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
                    }
                }
            }
            .onChange(of: chatCoordinator.aiManager.streamingContent) { _, _ in
                if let content = chatCoordinator.aiManager.streamingContent, !content.isEmpty {
                    // Immediate scroll when streaming, regardless of text field focus
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollViewProxy.scrollTo(
                                "bottom_padding",
                                anchor: .bottom
                            )
                        }
                    }
                }
            }
            .onChange(of: chatCoordinator.uiManager.currentState) { _, newState in
                // Auto-scroll immediately when entering streaming state
                if newState == .streaming {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            scrollViewProxy.scrollTo(
                                "bottom_padding",
                                anchor: .bottom
                            )
                        }
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { _, focused in
                // Scroll to show last message when keyboard appears
                if focused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
