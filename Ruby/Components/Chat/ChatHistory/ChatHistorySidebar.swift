//
//  ChatHistorySidebar.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct ChatHistorySidebar: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @Binding var isOpen: Bool
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var dragOffset: CGFloat = 0
    
    private let sidebarWidth: CGFloat = 320
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background overlay
                if isOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isOpen = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Sidebar content
                VStack(spacing: 0) {
                    // Search bar with exit button
                    HStack(spacing: 12) {
                        SearchBar(text: $searchText)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isOpen = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Chat history list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSessions, id: \.id) { session in
                                ChatHistoryRow(
                                    session: session,
                                    onTap: {
                                        Task {
                                            await chatCoordinator.loadSession(session)
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isOpen = false
                                            }
                                        }
                                    },
                                    onDelete: {
                                        Task {
                                            await chatCoordinator.deleteSession(session)
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    
                    Spacer()
                    
                    // Bottom actions
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        Button("Clear All History") {
                            showingDeleteAlert = true
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: sidebarWidth)
                .frame(maxHeight: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 0))
                .shadow(radius: 10)
                .offset(x: isOpen ? dragOffset : -sidebarWidth + dragOffset)
                .gesture(
                  DragGesture()
                    .onChanged { value in
                      let translationX = value.translation.width
                      if isOpen {
                        dragOffset = min(0, translationX)
                      } else {
                        dragOffset = max(-sidebarWidth, translationX)
                      }
                    }
                    .onEnded { value in
                      let translationX = value.translation.width
                      let predictedEndX = value.predictedEndTranslation.width
                      let velocityApprox = predictedEndX - translationX

                      withAnimation(.easeInOut(duration: 0.3)) {
                        if isOpen {
                          if translationX < -sidebarWidth * 0.3 || velocityApprox < -500 {
                            isOpen = false
                          }
                        } else {
                          if translationX > sidebarWidth * 0.3 || velocityApprox > 500 {
                            isOpen = true
                          }
                        }
                        dragOffset = 0
                      }
                    }
                )
                .alert("Clear All Data", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Clear All", role: .destructive) {
                        Task {
                            await chatCoordinator.clearAllData()
                        }
                    }
                } message: {
                    Text("This will permanently delete all chat history. This action cannot be undone.")
                }
            }
        }
    }
    
    private var filteredSessions: [ConversationSession] {
        if searchText.isEmpty {
            return chatCoordinator.sessionManager.savedSessions
        } else {
            return chatCoordinator.sessionManager.savedSessions.filter { session in
                session.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
