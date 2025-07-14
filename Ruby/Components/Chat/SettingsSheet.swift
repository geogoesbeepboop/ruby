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
                                    .foregroundStyle(Color(hex: "fc9afb"))
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
                        isOn: .constant(chatStore.settings.voiceEnabled)
                    )
                    Toggle(
                        "Streaming Responses",
                        isOn: .constant(chatStore.settings.streamingEnabled)
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
