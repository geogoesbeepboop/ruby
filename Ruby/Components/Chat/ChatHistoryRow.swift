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
                    .foregroundStyle(.black)
                    .lineLimit(1)
                
                Text(session.lastMessage?.content ?? "No messages")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                
                HStack {
                    Text(session.lastModified, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Text("\(session.messageCount) messages")
                        .font(.caption)
                        .foregroundStyle(.black)
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
}
