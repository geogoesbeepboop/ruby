//
//  WorkflowStreamingViews.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import SwiftUI
import FoundationModels

// MARK: - Search Workflow Views

@available(iOS 26.0, *)
struct SearchStreamingView: View {
    let searchResults: SearchResults.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with search query
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                
                if let query = searchResults.query {
                    Text("Searching: \(query)")
                        .contentTransition(.opacity)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Searching...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            // Search results as they come in
            if let results = searchResults.results, !results.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Found \(results.count) result(s):")
                        .contentTransition(.numericText())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    ForEach(Array(results.prefix(3).enumerated()), id: \.offset) { index, result in
                        SearchResultRow(result: result, index: index)
                    }
                    
                    if results.count > 3 {
                        Text("... and \(results.count - 3) more")
                            .contentTransition(.numericText())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding(.top, 8)
            }
            
            // Synthesized answer as it's generated
            if let answer = searchResults.synthesizedAnswer, !answer.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Answer:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text(answer)
                        .contentTransition(.opacity)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 8)
            }
            
            // Reliability assessment
            if let reliability = searchResults.reliability {
                SearchReliabilityView(reliability: reliability)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

@available(iOS 26.0, *)
struct SearchResultRow: View {
    let result: SearchResults.SearchResult.PartiallyGenerated
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index + 1).")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 4) {
                if let title = result.title {
                    Text(title)
                        .contentTransition(.opacity)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                
                if let summary = result.summary {
                    Text(summary)
                        .contentTransition(.opacity)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                if let source = result.source {
                    Text(source)
                        .contentTransition(.opacity)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontDesign(.monospaced)
                }
            }
            
            Spacer()
            
            if let relevance = result.relevance {
                RelevanceIndicator(relevance: relevance)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@available(iOS 26.0, *)
struct SearchReliabilityView: View {
    let reliability: SearchResults.SearchReliability.PartiallyGenerated
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(reliabilityColor)
                .font(.caption)
            
            Text("Reliability:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let confidence = reliability.confidence {
                Text("\(Int(confidence * 100))%")
                    .contentTransition(.numericText())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(reliabilityColor)
            }
            
            if let sources = reliability.corroboratingSources {
                Text("• \(sources) sources")
                    .contentTransition(.numericText())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let quality = reliability.sourceQuality {
                QualityBadge(quality: quality)
            }
        }
        .padding(.top, 8)
    }
    
    private var reliabilityColor: Color {
        guard let confidence = reliability.confidence else { return .gray }
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .orange }
        else { return .red }
    }
}

@available(iOS 26.0, *)
struct RelevanceIndicator: View {
    let relevance: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(Double(level) * 0.2 <= relevance ? .blue : .gray.opacity(0.3))
                    .frame(width: 3, height: 3)
            }
        }
        .contentTransition(.opacity)
    }
}

@available(iOS 26.0, *)
struct QualityBadge: View {
    let quality: SearchResults.SearchReliability.SourceQuality.PartiallyGenerated
    
    var body: some View {
        Text(quality.rawValue.uppercased())
            .contentTransition(.opacity)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(qualityColor.opacity(0.2))
            .foregroundColor(qualityColor)
            .clipShape(Capsule())
    }
    
    private var qualityColor: Color {
        switch quality {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        case .mixed: return .purple
        case .unknown: return .gray
        }
    }
}

// MARK: - Creative Workflow Views

@available(iOS 26.0, *)
struct CreativeStreamingView: View {
    let creativeContent: CreativeContent.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with content type
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.purple)
                
                if let contentType = creativeContent.contentType {
                    Text("Creating \(contentType.rawValue)...")
                        .contentTransition(.opacity)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Creating content...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let quality = creativeContent.quality {
                    QualityIndicator(quality: quality)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Style and constraints
            if let style = creativeContent.style {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    Text("Style: \(style)")
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let isComplete = creativeContent.isComplete {
                        Label(isComplete ? "Complete" : "Draft", 
                              systemImage: isComplete ? "checkmark.circle.fill" : "clock.fill")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(isComplete ? .green : .orange)
                    }
                }
            }
            
            // Creative content
            if let content = creativeContent.content, !content.isEmpty {
                ScrollView {
                    Text(content)
                        .contentTransition(.opacity)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(.top, 8)
            }
            
            // Constraints followed
            if let constraints = creativeContent.constraints, !constraints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Constraints followed:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    
                    ForEach(constraints.prefix(3), id: \.self) { constraint in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)
                            
                            Text(constraint)
                                .contentTransition(.opacity)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

@available(iOS 26.0, *)
struct QualityIndicator: View {
    let quality: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(qualityColor)
                .font(.caption)
            
            Text("\(Int(quality * 100))%")
                .contentTransition(.numericText())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(qualityColor)
        }
    }
    
    private var qualityColor: Color {
        if quality >= 0.8 {
            return .green
        } else if quality >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview
//
//@available(iOS 26.0, *)
//#Preview {
//    ScrollView {
//        VStack(spacing: 16) {
//            SearchStreamingView(searchResults: SearchResults.PartiallyGenerated(
//                query: "Swift programming best practices",
//                results: [],
//                synthesizedAnswer: "Swift programming follows several key best practices...",
//                reliability: SearchResults.SearchReliability.PartiallyGenerated(
//                    confidence: 0.85,
//                    corroboratingSources: 5,
//                    sourceQuality: SearchResults.SearchReliability.SourceQuality.PartiallyGenerated(content: .high)
//                )
//            ))
//            
//            CreativeStreamingView(creativeContent: CreativeContent.PartiallyGenerated(
//                content: "Once upon a time, in a world where code came to life...",
//                contentType: .story,
//                style: "fantasy adventure",
//                quality: 0.92,
//                constraints: ["family-friendly", "under 500 words"],
//                isComplete: false
//            ))
//        }
//        .padding()
//    }
//}
