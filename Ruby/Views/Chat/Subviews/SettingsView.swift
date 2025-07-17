//
//  SettingsView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct SettingsView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                MaterialBackground(intensity: 0.5)
                    .ignoresSafeArea()
                
                List {
                    // AI Persona Section
                    Section("AI Personality") {
                        ForEach(AIPersona.allCases, id: \.self) { persona in
                            PersonaRow(
                                persona: persona,
                                isSelected: chatStore.settings.selectedPersona == persona
                            ) {
                                chatStore.updatePersona(persona)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // Preferences Section
                    Section("Preferences") {
                        SettingsToggle(
                            title: "Voice Input",
                            subtitle: "Enable voice recording",
                            isOn: .constant(chatStore.settings.voiceEnabled)
                        )
                        
                        SettingsToggle(
                            title: "Streaming Responses",
                            subtitle: "See AI responses as they're generated",
                            isOn: .constant(chatStore.settings.streamingEnabled)
                        )
                        
                        SettingsToggle(
                            title: "Auto-save Conversations",
                            subtitle: "Automatically save chat history",
                            isOn: .constant(chatStore.settings.autoSaveConversations)
                        )
                    }
                    .listRowBackground(Color.clear)
                    
                    // Actions Section
                    Section("Actions") {
                        Button(action: {
                            Task {
                                await chatStore.startNewSession()
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.brandPrimary)
                                Text("New Conversation")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                        
                        Button(action: {
                            // Export conversation functionality
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                                Text("Export Chat")
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
            }
        }
    }
}
