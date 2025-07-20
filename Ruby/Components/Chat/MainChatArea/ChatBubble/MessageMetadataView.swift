//
//  MessageMetadataView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

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
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
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
