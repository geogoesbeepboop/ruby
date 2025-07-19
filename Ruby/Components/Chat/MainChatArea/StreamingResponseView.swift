//
//  StreamingResponseView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct StreamingResponseView: View {
    let response: ChatResponse.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Response content - progressive disclosure
            if let content = response.content, !content.isEmpty {
                Text(content)
                    .contentTransition(.opacity)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .animation(.easeInOut(duration: 0.3), value: content)
            } else {
                // Placeholder while content is generating
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating response...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Response metadata - shows as it becomes available
            if let tone = response.tone {
                HStack {
                    Image(systemName: "theatermasks.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("Tone: \(tone.capitalized)")
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Confidence indicator
                    if let confidence = response.confidence {
                        ConfidenceIndicator(confidence: confidence)
                    }
                }
                .padding(.top, 4)
            }
            
            // Category and topics
            if let category = response.category {
                HStack {
                    Image(systemName: categoryIcon(for: category))
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(category.rawValue.capitalized)
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Topics as they stream in
                    if let topics = response.topics, !topics.isEmpty {
                        Text("Topics: \(topics.prefix(3).joined(separator: ", "))")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            // Follow-up indicator
            if let requiresFollowUp = response.requiresFollowUp, requiresFollowUp {
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Follow-up suggested")
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .italic()
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func categoryIcon(for category: ChatResponse.ResponseCategory) -> String {
        switch category {
        case .answer:
            return "checkmark.circle.fill"
        case .question:
            return "questionmark.circle.fill"
        case .creative:
            return "paintbrush.fill"
        case .analysis:
            return "chart.bar.fill"
        case .tool_result:
            return "wrench.fill"
        case .conversation:
            return "bubble.left.and.bubble.right.fill"
        case .explanation:
            return "lightbulb.fill"
        }
    }
}

@available(iOS 26.0, *)
struct ConversationTurnStreamingView: View {
    let turn: ConversationTurn.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User analysis section
            if let userAnalysis = turn.userAnalysis {
                UserAnalysisView(analysis: userAnalysis)
            }
            
            // Response section
            if let response = turn.response {
                StreamingResponseView(response: response)
            }
            
            // Metadata section
            if let metadata = turn.metadata {
                ConversationMetadataView(metadata: metadata)
            }
        }
    }
}

@available(iOS 26.0, *)
struct UserAnalysisView: View {
    let analysis: ConversationTurn.UserInputAnalysis.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.fill.viewfinder")
                    .foregroundColor(.indigo)
                    .font(.caption)
                
                Text("Input Analysis")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.indigo)
                
                Spacer()
            }
            
            HStack {
                if let intent = analysis.intent {
                    Label(intent.rawValue.capitalized, systemImage: "target")
                        .contentTransition(.opacity)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let complexity = analysis.complexity {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= complexity ? .indigo : .gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .contentTransition(.opacity)
                }
            }
            
            if let entities = analysis.entities, !entities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entities.prefix(5), id: \.self) { entity in
                            Text(entity)
                                .contentTransition(.opacity)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.indigo.opacity(0.1))
                                .foregroundColor(.indigo)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.indigo.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.indigo.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

@available(iOS 26.0, *)
struct ConversationMetadataView: View {
    let metadata: ConversationTurn.ConversationMetadata.PartiallyGenerated
    
    var body: some View {
        HStack {
            if let processingTime = metadata.processingTime {
                Label("\(String(format: "%.2f", processingTime))s", systemImage: "stopwatch")
                    .contentTransition(.numericText())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let toolsUsed = metadata.toolsUsed, toolsUsed > 0 {
                Label("\(toolsUsed) tools", systemImage: "wrench.and.screwdriver")
                    .contentTransition(.numericText())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let streamingUsed = metadata.streamingUsed, streamingUsed {
                Label("Streaming", systemImage: "wave.3.right")
                    .contentTransition(.opacity)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            if let tokens = metadata.estimatedTokens {
                Label("\(tokens) tokens", systemImage: "textformat.abc")
                    .contentTransition(.numericText())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.gray.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Preview
//
//@available(iOS 26.0, *)
//#Preview {
//    ScrollView {
//        VStack(spacing: 16) {
//            // Example of streaming response
//            StreamingResponseView(response: ChatResponse.PartiallyGenerated(
//                content: "This is an example of a streaming response that's being generated in real-time. As you can see, the content appears progressively as it becomes available.",
//                tone: "helpful",
//                confidence: 0.85,
//                category: ChatResponse.ResponseCategory.answer,
//                topics: ["example", "streaming", "real-time"],
//                requiresFollowUp: false
//            ))
//            
//            // Example with confidence indicator
//            ConfidenceIndicator(confidence: 0.92)
//        }
//        .padding()
//    }
//}
