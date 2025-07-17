//
//  StreamingMessageView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct StreamingMessageView: View {
    let content: String
    @State private var displayedContent = ""
    @State private var cursorVisible = true

    var body: some View {
        ChatBubble(isUser: false, timestamp: Date()) {
            HStack {
                Text(displayedContent)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(.primary)

                if cursorVisible {
                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: 2, height: 20)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(
                                autoreverses: true
                            ),
                            value: cursorVisible
                        )
                }

                Spacer()
            }
        }
        .id("streaming")
        .onChange(of: content) { _, newContent in
            withAnimation(.easeOut(duration: 0.1)) {
                displayedContent = newContent
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
            ) {
                cursorVisible.toggle()
            }
        }
    }
}
