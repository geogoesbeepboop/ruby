//
//  AIStatusIndicator.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct AIStatusIndicator: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .animation(
                    .easeInOut(duration: 0.5),
                    value: chatCoordinator.uiManager.currentState
                )

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.black)
        }
    }

    private var statusColor: Color {
        switch chatCoordinator.uiManager.currentState {
        case .activeChat:
            return Color.green.opacity(1.0)
        case .aiThinking:
            return Color.brandPrimary
        case .streaming:
            return Color.brandSecondary
        case .voiceListening:
            return .blue
        case .error:
            return .red
        }
    }

    private var statusText: String {
        switch chatCoordinator.uiManager.currentState {
        case .activeChat:
            return "Online"
        case .aiThinking:
            return "Thinking..."
        case .streaming:
            return "Typing..."
        case .voiceListening:
            return "Listening"
        case .error(let message):
            return "Error"
        }
    }
}
