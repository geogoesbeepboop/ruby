//
//  MessageContextMenu.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI


@available(iOS 26.0, *)
struct MessageContextMenu: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    let message: ChatMessage

    var body: some View {
        Group {
            Button(action: { copyMessage() }) {
                Label("Copy", systemImage: "doc.on.doc")
            }

            if !message.isUser {
                Button(action: { regenerateResponse() }) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }

            Button(role: .destructive, action: { deleteMessage() }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func copyMessage() {
        UIPasteboard.general.string = message.content
    }

    private func regenerateResponse() {
        // Implementation for regenerating AI response
    }

    private func deleteMessage() {
        Task {
            await chatCoordinator.deleteMessage(message)
        }
    }
}
