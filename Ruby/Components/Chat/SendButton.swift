//
//  SendButton.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct SendButton: View {
    let canSendMessage: Bool
    let sendMessage: () -> Void

    var body: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title3)
                .foregroundStyle(
                    canSendMessage
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color.brandPrimary, Color.brandSecondary,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(.secondary)
                )
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .disabled(!canSendMessage)
        .accessibilityLabel("Send message")
    }
}
