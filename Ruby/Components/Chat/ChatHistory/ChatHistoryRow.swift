//
//  ChatHistoryRow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ChatHistoryRow: View {
    let session: ConversationSession
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(truncatedTitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(session.lastMessage?.content ?? "No messages")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                
                HStack {
                    Text(formattedLastModified)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(session.messageCount) messages")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private var truncatedTitle: String {
        if session.title.count > 40 {
            return String(session.title.prefix(40)) + "..."
        }
        return session.title
    }
    
    private var formattedLastModified: String {
        let now = Date()
        let interval = now.timeIntervalSince(session.lastModified)
        
        // If more than 7 days old, show absolute date to prevent drift
        if interval > 7 * 24 * 60 * 60 {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: session.lastModified)
        }
        
        // For recent sessions, use relative time but cap it to prevent indefinite counting
        if interval < 60 {
            return "Just now"
        } else if interval < 60 * 60 {
            let minutes = Int(interval / 60)
            return "\(minutes) min ago"
        } else if interval < 24 * 60 * 60 {
            let hours = Int(interval / (60 * 60))
            return "\(hours)h ago"
        } else {
            let days = Int(interval / (24 * 60 * 60))
            return "\(days)d ago"
        }
    }
}
