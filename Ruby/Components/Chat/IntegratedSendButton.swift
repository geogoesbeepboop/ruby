//
//  IntegratedSendButton.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct IntegratedSendButton: View {
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
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(.secondary)
                )
                .frame(width: 32, height: 32)
        }
        .disabled(!canSendMessage)
        .accessibilityLabel("Send message")
    }
}
