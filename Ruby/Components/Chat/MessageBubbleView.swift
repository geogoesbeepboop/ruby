//
//  MessageBubbleView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct MessageBubbleView: View {
    let message: ChatMessage
    let onLongPress: (UUID) -> Void
    @State private var showingContextMenu = false

    var body: some View {
        ChatBubble(isUser: message.isUser, timestamp: message.timestamp) {
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8)
            {
                // Message content
                Text(message.content)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)

                // Reactions
                if !message.reactions.isEmpty {
                    ReactionRow(reactions: message.reactions)
                }

                // Metadata (for AI messages)
                if !message.isUser, let metadata = message.metadata {
                    MessageMetadataView(metadata: metadata)
                }
            }
        }
        .contextMenu {
            MessageContextMenu(message: message)
        }
        .onLongPressGesture {
            onLongPress(message.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let sender = message.isUser ? "You" : "AI"
        let time = DateFormatter.timeFormatter.string(from: message.timestamp)
        return "\(sender) at \(time): \(message.content)"
    }
}
