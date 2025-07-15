//
//  ChatHistorySheet.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ChatHistorySheet: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with blur effect for inactive area
                MaterialBackground(intensity: 0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Chat history list
                    List {
                        ForEach(filteredSessions, id: \.id) { session in
                            ChatHistoryRow(
                                session: session,
                                onTap: {
                                    Task {
                                        await chatStore.loadSession(session)
                                        dismiss()
                                    }
                                },
                                onDelete: {
                                    chatStore.deleteSession(session)
                                }
                            )
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        showingDeleteAlert = true
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
            .alert("Clear All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    // Clear all chat history
                    for session in chatStore.savedSessions {
                        chatStore.deleteSession(session)
                    }
                }
            } message: {
                Text("This will permanently delete all chat history. This action cannot be undone.")
            }
        }
    }
    
    private var filteredSessions: [ConversationSession] {
        if searchText.isEmpty {
            return chatStore.savedSessions
        } else {
            return chatStore.savedSessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
