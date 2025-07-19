//
//  ConfidenceIndicator.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/19/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ConfidenceIndicator: View {
    let confidence: Double
    
    private var color: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var icon: String {
        if confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.6 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    VStack(spacing: 8) {
        ConfidenceIndicator(confidence: 0.95)
        ConfidenceIndicator(confidence: 0.75)
        ConfidenceIndicator(confidence: 0.45)
    }
    .padding()
}