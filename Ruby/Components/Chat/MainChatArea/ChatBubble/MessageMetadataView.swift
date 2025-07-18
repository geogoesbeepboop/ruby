//
//  MessageMetadataView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
//import SwiftUI
//
//@available(iOS 26.0, *)
//struct MessageMetadataView: View {
//    let metadata: MessageMetadata
//
//    var body: some View {
//        HStack(spacing: 8) {
//            if let processingTime = metadata.processingTime {
//                Text("\(String(format: "%.1f", processingTime))s")
//                    .font(.caption2)
//                    .foregroundStyle(.tertiary)
//            }
//
//            // Tokens display removed for more natural conversation flow
//            // if let tokens = metadata.tokens {
//            //     Text("\(tokens) tokens")
//            //         .font(.caption2)
//            //         .foregroundStyle(.tertiary)
//            // }
//
//            if let confidence = metadata.confidence {
//                HStack(spacing: 2) {
//                    Image(systemName: "chart.bar.fill")
//                        .font(.caption2)
//                    Text("\(Int(confidence * 100))%")
//                        .font(.caption2)
//                }
//                .foregroundStyle(.tertiary)
//            }
//        }
//    }
//}
