//
//  ChatHeaderView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ChatHeaderView: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @State private var showingSettings = false
    @Binding var showingChatHistory: Bool

    var body: some View {
        ZStack {
            // 1. Center Title and Subtitle
            VStack(spacing: 2) {
                Text("Lotus")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        Color.brandPrimary,
                    )
                Text(chatCoordinator.uiManager.settings.selectedPersona.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                if chatCoordinator.sessionManager.currentSession != nil || !chatCoordinator.uiManager.messages.filter({ $0.isUser }).isEmpty {
                    Button(action: {
                        Task {
                            await chatCoordinator.startNewSession()
                        }
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
        .blurredBackground()
        .sheet(isPresented: $showingSettings) {
            SettingsSheet()
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    @Previewable @State var showingHistory = false
    ChatHeaderView(showingChatHistory: $showingHistory)
        .environment(ChatCoordinator())
}
