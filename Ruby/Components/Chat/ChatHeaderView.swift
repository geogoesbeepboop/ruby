//
//  ChatHeaderView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ChatHeaderView: View {
    @Environment(ChatStore.self) private var chatStore
    @State private var showingSettings = false
    @State private var showingChatHistory = false

    var body: some View {
        ZStack {
            // 1. Center Title and Subtitle
            VStack(spacing: 2) {
                Text("Lotus")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary, Color.brandSecondary,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text(chatStore.settings.selectedPersona.rawValue)
                    .font(.caption)
                    .foregroundStyle(.black)
            }

            // 2. Align Buttons to the Sides
            HStack {
                // Chat History Menu on the left (replacing AI Status Indicator)
                Button(action: { showingChatHistory = true }) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                }
                .accessibilityLabel("Open chat history")

                Spacer()

                // Save session button
                if chatStore.currentSession != nil || !chatStore.messages.filter({ $0.isUser }).isEmpty {
                    Button(action: {
                        chatStore.saveAndEndSession()
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.title3)
                            .foregroundStyle(Color.brandPrimary)
                    }
                    .accessibilityLabel("Save and end session")
                }

                // Settings button on the right
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(Color.brandPrimary)
                }
                .accessibilityLabel("Open settings")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 5) // Adjust for status bar
        .padding(.bottom, 10)
        .background(
            // Transparent Blue Overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.mix(.teal, .white, ratio: 0.25).opacity(0.8), location: 0.0),
                    .init(color: Color.mix(.teal, .white, ratio: 0.25).opacity(0.7), location: 0.25),
                    .init(color: Color.mix(.teal, .white, ratio: 0.25).opacity(0.6), location: 0.5),
                    .init(color: Color.mix(.teal, .white, ratio: 0.25).opacity(0.5), location: 0.75),
                    .init(color: Color.mix(.teal, .white, ratio: 0.25).opacity(0.4), location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .background(.ultraThinMaterial) // Frosted glass effect
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showingChatHistory) {
            ChatHistorySheet()
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    TypingBubbleView()
        .environment(ChatStore())
}
