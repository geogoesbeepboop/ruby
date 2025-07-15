//
//  ChatBubble.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct ChatBubble<Content: View>: View {
    let content: Content
    let isUser: Bool
    let timestamp: Date

    init(isUser: Bool, timestamp: Date, @ViewBuilder content: () -> Content) {
        self.isUser = isUser
        self.timestamp = timestamp
        self.content = content()
    }

    var body: some View {
        HStack {
            if isUser { Spacer() }

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

                Text(timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
            }

            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

@available(iOS 26.0, *)
#Preview {
    ChatBubble(isUser: false, timestamp: Date()) {
        VStack(alignment: false ? .trailing : .leading, spacing: 8)
        {
            // Message content
            Text("Hello")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }        .environment(ChatStore())
}

