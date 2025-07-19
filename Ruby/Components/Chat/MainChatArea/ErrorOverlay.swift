//
//  ErrorOverlay.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ErrorOverlay: View {
    let error: ChatError
    let dismissAction: () -> Void
    @State private var isVisible = false
    
    private var errorTitle: String {
        switch error {
        case .guardrailViolation:
            return "Content Warning"
        case .exceededContextWindowSize:
            return "Conversation Too Long"
        case .rateLimited:
            return "Rate Limited"
        case .assetsUnavailable:
            return "AI Unavailable"
        case .decodingFailure:
            return "Processing Error"
        default:
            return "Error"
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            GlassEffectContainer(
                cornerRadius: 16,
                blurRadius: 12,
                opacity: 0.5
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(errorTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text(error.localizedDescription)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: dismissAction) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismissAction()
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Error notification: \(error.localizedDescription)")
        .accessibilityHint("Will dismiss automatically or tap X to close")
    }
}
