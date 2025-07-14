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
                    opacity: isUser ? 0.4 : 0.2
                ) {
                    content
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background {
                    if isUser {
                        LinearGradient(
                            colors: [
                                Color(hex: "fc9afb").opacity(0.3),
                                Color(hex: "9b6cb0").opacity(0.2),
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
