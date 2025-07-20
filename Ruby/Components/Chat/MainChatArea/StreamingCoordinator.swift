//
//  StreamingCoordinator.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct StreamingCoordinator: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    
    var body: some View {
        Group {
            // Display streaming content when available
            if chatCoordinator.uiManager.currentState == .streaming {
                streamingContent
            }
        }
        .id("live_response")
    }
    
    @ViewBuilder
    private var streamingContent: some View {
        // TODO: When workflow managers are exposed through ChatCoordinator,
        // we can detect which one is active and show the appropriate view
        
        // For now, show the enhanced streaming view with available content
//        if let streamingContent = chatCoordinator.aiManager.streamingContent, !streamingContent.isEmpty {
//            
//            // Try to detect the type of response based on content characteristics
//            if isSearchResponse(streamingContent) {
//                SearchResponseStreamingView(content: streamingContent)
//            } else if isCreativeResponse(streamingContent) {
//                CreativeResponseStreamingView(content: streamingContent)
//            } else {
//                // Default enhanced streaming view
//                DefaultStreamingResponseView(content: streamingContent)
//            }
//        } else {
//            // Show processing indicator
//            ProcessingIndicatorView()
//        }
    }
    
    // MARK: - Content Type Detection
    
    private func isSearchResponse(_ content: String) -> Bool {
        let searchKeywords = ["search", "found", "results", "sources", "according to", "research"]
        return searchKeywords.contains { content.lowercased().contains($0) }
    }
    
    private func isCreativeResponse(_ content: String) -> Bool {
        let creativeKeywords = ["once upon", "story", "poem", "creative", "imagine", "# "]
        return creativeKeywords.contains { content.lowercased().contains($0) }
    }
}

//@available(iOS 26.0, *)
//struct DefaultStreamingResponseView: View {
//    let content: String
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            // AI avatar or indicator
//            Circle()
//                .fill(.blue.gradient)
//                .frame(width: 32, height: 32)
//                .overlay(
//                    Image(systemName: "brain.head.profile")
//                        .foregroundColor(.white)
//                        .font(.system(size: 14, weight: .medium))
//                )
//            
//            VStack(alignment: .leading, spacing: 8) {
//                // Content with typing animation
//                Text(content)
//                    .font(.body)
//                    .foregroundColor(.primary)
//                    .multilineTextAlignment(.leading)
//                    .animation(.easeInOut(duration: 0.3), value: content)
//            }
//            
//            Spacer(minLength: 40)
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 12)
//        .background(
//            RoundedRectangle(cornerRadius: 18)
//                .fill(.blue.opacity(0.05))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 18)
//                        .stroke(.blue.opacity(0.2), lineWidth: 1)
//                )
//        )
//    }
//}
//
//@available(iOS 26.0, *)
//struct SearchResponseStreamingView: View {
//    let content: String
//    @State private var searchProgress: Double = 0.0
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Search header
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.blue)
//                    .font(.headline)
//                
//                Text("Searching & Analyzing")
//                    .font(.headline)
//                    .foregroundColor(.blue)
//                
//                Spacer()
//                
//                ProgressView(value: searchProgress, total: 1.0)
//                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
//                    .frame(width: 60)
//            }
//            
//            // Search results content
//            Text(content)
//                .font(.body)
//                .foregroundColor(.primary)
//                .multilineTextAlignment(.leading)
//                .animation(.easeInOut(duration: 0.3), value: content)
//            
//            // Search indicators
//            HStack {
//                Label("Live Search", systemImage: "globe")
//                    .font(.caption)
//                    .foregroundColor(.blue)
//                
//                Spacer()
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(.blue.opacity(0.05))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(.blue.opacity(0.3), lineWidth: 1)
//                )
//        )
//        .onAppear {
//            withAnimation(.linear(duration: 3.0)) {
//                searchProgress = 0.8
//            }
//        }
//    }
//}
//
//@available(iOS 26.0, *)
//struct CreativeResponseStreamingView: View {
//    let content: String
//    @State private var creativityLevel: Double = 0.0
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // Creative header
//            HStack {
//                Image(systemName: "paintbrush.fill")
//                    .foregroundColor(.purple)
//                    .font(.headline)
//                
//                Text("Creating Content")
//                    .font(.headline)
//                    .foregroundColor(.purple)
//                
//                Spacer()
//                
//                HStack(spacing: 2) {
//                    ForEach(1...5, id: \.self) { level in
//                        Star(filled: Double(level) <= creativityLevel)
//                            .foregroundColor(.purple)
//                            .frame(width: 12, height: 12)
//                    }
//                }
//            }
//            
//            // Creative content
//            Text(content)
//                .font(.body)
//                .foregroundColor(.primary)
//                .multilineTextAlignment(.leading)
//                .animation(.easeInOut(duration: 0.3), value: content)
//            
//            // Creative indicators
//            HStack {
//                Label("Creative Mode", systemImage: "sparkles")
//                    .font(.caption)
//                    .foregroundColor(.purple)
//                
//                Spacer()
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(.purple.opacity(0.05))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(.purple.opacity(0.3), lineWidth: 1)
//                )
//        )
//        .onAppear {
//            withAnimation(.easeInOut(duration: 2.0)) {
//                creativityLevel = 4.2
//            }
//        }
//    }
//}
//
//@available(iOS 26.0, *)
//struct Star: View {
//    let filled: Bool
//    
//    var body: some View {
//        Image(systemName: filled ? "star.fill" : "star")
//            .font(.caption)
//    }
//}
//
//@available(iOS 26.0, *)
//struct ThinkingIndicatorView: View {
//    @State private var thinking = false
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "brain.head.profile")
//                .foregroundColor(.orange)
//                .font(.headline)
//            
//            Text("AI is thinking...")
//                .font(.headline)
//                .foregroundColor(.orange)
//            
//            Spacer()
//            
//            HStack(spacing: 4) {
//                ForEach(0..<3) { index in
//                    Circle()
//                        .fill(.orange)
//                        .frame(width: 8, height: 8)
//                        .scaleEffect(thinking ? 1.2 : 0.8)
//                        .animation(
//                            .easeInOut(duration: 0.6)
//                            .repeatForever(autoreverses: true)
//                            .delay(Double(index) * 0.2),
//                            value: thinking
//                        )
//                }
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(.orange.opacity(0.1))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(.orange.opacity(0.3), lineWidth: 1)
//                )
//        )
//        .onAppear {
//            thinking = true
//        }
//    }
//}
//
//@available(iOS 26.0, *)
//struct ProcessingIndicatorView: View {
//    var body: some View {
//        HStack {
//            ProgressView()
//                .scaleEffect(0.8)
//            
//            Text("Processing...")
//                .font(.body)
//                .foregroundColor(.secondary)
//                .italic()
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(.gray.opacity(0.05))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(.gray.opacity(0.2), lineWidth: 1)
//                )
//        )
//    }
//}

// MARK: - Preview

@available(iOS 26.0, *)
#Preview {
    ScrollView {
        VStack(spacing: 16) {
//            DefaultStreamingResponseView(content: "This is a default streaming response that shows how content appears as it's being generated...")
//            
//            SearchResponseStreamingView(content: "Based on search results, I found several relevant sources about Swift programming...")
//            
//            CreativeResponseStreamingView(content: "Once upon a time, in a magical kingdom where code came to life...")
//            
//            ThinkingIndicatorView()
//            
//            ProcessingIndicatorView()
        }
        .padding()
    }
}
