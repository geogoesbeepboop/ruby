//
//  ErrorStateView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ErrorStateView: View {
    @Environment(ChatStore.self) private var chatStore
    let errorMessage: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Error message
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(errorMessage)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Action buttons
            VStack(spacing: 16) {
                // Retry button
                Button(action: {
                    Task {
                        await chatStore.initializeAI()
                    }
                }) {
                    GlassEffectContainer(
                        cornerRadius: 25,
                        blurRadius: 10,
                        opacity: 0.4
                    ) {
                        Text("Try Again")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.brandPrimary, Color.brandSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(maxWidth: 200, minHeight: 50)
                    }
                }
                
                // Return to chat button
                if !chatStore.messages.isEmpty {
                    Button(action: {
                        chatStore.currentState = .activeChat
                    }) {
                        Text("Return to Chat")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error occurred: \(errorMessage). Try again or return to chat options available.")
    }
}
