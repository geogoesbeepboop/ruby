//
//  EnhancedMessageBubble.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct EnhancedMessageBubble: View {
    let message: ChatMessage
    let onLongPress: (UUID) -> Void
    @State private var showMetadata = false
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                // Main message content
                messageContent
                // Enhanced metadata display
                if let metadata = message.metadata, showMetadata {
                    MessageMetadataView(metadata: metadata)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                // Timestamp and reactions - always aligned to right side of message
                HStack {
                    if !message.isUser {
                        metadataToggleButton
                        
                        if let metadata = message.metadata, let confidence = metadata.confidence {
                            ConfidenceIndicator(confidence: confidence)
                        }
                    }
                    
                    Spacer()
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, message.isUser ? 16 : 8) // Align with bubble padding
                
                // Reactions
                if !message.reactions.isEmpty {
                    MessageReactionsView(reactions: message.reactions)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMetadata)
    }
    
    private var messageContent: some View {
        Text(message.content)
            .font(.body)
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(message.isUser ? .blue : .gray.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(message.isUser ? .clear.opacity(0.2) : .gray.opacity(0.5), lineWidth: 1)
                    )
            )
            .foregroundColor(.primary)
            .onLongPressGesture {
                onLongPress(message.id)
            }
            .contextMenu {
                MessageContextMenuContent(message: message)
            }
    }
    
    private var metadataToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showMetadata.toggle()
            }
        }) {
            Image(systemName: showMetadata ? "info.circle.fill" : "info.circle")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 26.0, *)
struct MessageMetadataView: View {
    let metadata: MessageMetadata
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Message Details")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            if let processingTime = metadata.processingTime {
                MetadataRow(
                    icon: "stopwatch",
                    label: "Processing Time",
                    value: "\(String(format: "%.2f", processingTime))s"
                )
            }
            
            if let tokens = metadata.tokens {
                MetadataRow(
                    icon: "textformat.abc",
                    label: "Tokens",
                    value: "\(tokens)"
                )
            }
            
            if let confidence = metadata.confidence {
                MetadataRow(
                    icon: "gauge.medium",
                    label: "Confidence",
                    value: "\(Int(confidence * 100))%",
                    valueColor: confidenceColor(confidence)
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

@available(iOS 26.0, *)
struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color
    
    init(icon: String, label: String, value: String, valueColor: Color = .primary) {
        self.icon = icon
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue)
                .frame(width: 12)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

@available(iOS 26.0, *)
struct MessageReactionsView: View {
    let reactions: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(reactions, id: \.self) { reaction in
                Text(reaction)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

@available(iOS 26.0, *)
struct MessageContextMenuContent: View {
    let message: ChatMessage
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = message.content
        }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        Button(action: {
            // TODO: Implement edit functionality
        }) {
            Label("Edit", systemImage: "pencil")
        }
        
        Button(role: .destructive, action: {
            // TODO: Implement delete functionality
        }) {
            Label("Delete", systemImage: "trash")
        }
        
        if !message.isUser {
            Button(action: {
                // TODO: Implement regenerate functionality
            }) {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            EnhancedMessageBubble(
                message: ChatMessage(
                    content: "hihihihihihihihihihihihihihihi.",
                    isUser: false,
                    timestamp: Date(),
                    metadata: .init(
                        processingTime: 1.23,
                        tokens: 45,
                        confidence: 0.87
                    )
                ),
                onLongPress: { _ in }
            )
            
            EnhancedMessageBubble(
                message: ChatMessage(
                    content: "This is a user message.",
                    isUser: true,
                    timestamp: Date()
                ),
                onLongPress: { _ in }
            )
        }
        .padding()
    }
}
