//
//  MessageList.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct MessagesList: View {
    @Environment(ChatStore.self) private var chatStore
    @Binding var selectedMessageId: UUID?
    @Binding var showingReactionPicker: Bool

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                let sortedMessages = chatStore.messages.sorted {
                    $0.timestamp < $1.timestamp
                }
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedMessages) { message in
                        MessageBubbleView(
                            message: message,
                            onLongPress: { messageId in
                                selectedMessageId = messageId
                                showingReactionPicker = true
                            }
                        )
                        .id(message.id)
                    }

                    // AI typing bubble when thinking
                    if chatStore.currentState == .aiThinking {
                        TypingBubbleView()
                            .id("live_response")
                    }

                    // Streaming content when AI is responding
                    if chatStore.currentState == .streaming
                        && !chatStore.streamingContent.isEmpty
                    {
                        StreamingMessageView(
                            content: chatStore.streamingContent
                        )
                        .id("live_response")
                    }

                    Color.clear.frame(height: 16).id("bottom_padding")
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .onChange(of: chatStore.messages.count) { _, _ in
                withAnimation {
                    scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
                }
            }
            .onChange(of: chatStore.streamingContent) { _, _ in
                if !chatStore.streamingContent.isEmpty {
                    withAnimation {
                        scrollViewProxy.scrollTo(
                            "bottom_padding",
                            anchor: .bottom
                        )
                    }
                }
            }
            .onChange(of: chatStore.currentState) { _, newState in
                if newState == .aiThinking || newState == .streaming {
                    withAnimation {
                        scrollViewProxy.scrollTo(
                            "bottom_padding",
                            anchor: .bottom
                        )
                    }
                }
            }
            .onAppear {
                scrollViewProxy.scrollTo("bottom_padding", anchor: .bottom)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
