//
//  SettingsSheet.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct SettingsSheet: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("AI Persona") {
                    ForEach(AIPersona.allCases, id: \.self) { persona in
                        HStack {
                            Text(persona.rawValue)
                            Spacer()
                            if chatStore.settings.selectedPersona == persona {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            chatStore.updatePersona(persona)
                        }
                    }
                }

                Section("Preferences") {
                    Toggle(
                        "Voice Input",
                        isOn: Binding(
                            get: { chatStore.settings.voiceEnabled },
                            set: { newValue in
                                chatStore.settings.voiceEnabled = newValue
                                chatStore.saveSettings()
                            }
                        )
                    )
                    Toggle(
                        "Streaming Responses",
                        isOn: Binding(
                            get: { chatStore.settings.streamingEnabled },
                            set: { newValue in
                                chatStore.settings.streamingEnabled = newValue
                                chatStore.saveSettings()
                            }
                        )
                    )
                }

                Section {
                    Button("Start New Conversation") {
                        chatStore.startNewSession()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
