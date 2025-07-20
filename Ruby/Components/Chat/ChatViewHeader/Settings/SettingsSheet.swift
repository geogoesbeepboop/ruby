//
//  SettingsSheet.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct SettingsSheet: View {
    @Environment(ChatCoordinator.self) private var chatCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("AI Persona") {
                    ForEach(AIPersona.allCases, id: \.self) { persona in
                        HStack {
                            Text(persona.rawValue)
                            Spacer()
                            if chatCoordinator.uiManager.settings.selectedPersona == persona {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                await chatCoordinator.updatePersona(persona)
                            }
                        }
                    }
                }

                Section("Preferences") {
                    Toggle(
                        "Voice Input",
                        isOn: Binding(
                            get: { chatCoordinator.uiManager.settings.voiceEnabled },
                            set: { newValue in
                                var newSettings = chatCoordinator.uiManager.settings
                                newSettings.voiceEnabled = newValue
                                Task {
                                    await chatCoordinator.updateSettings(newSettings)
                                }
                            }
                        )
                    )
                    Toggle(
                        "Streaming Responses",
                        isOn: Binding(
                            get: { chatCoordinator.uiManager.settings.streamingEnabled },
                            set: { newValue in
                                var newSettings = chatCoordinator.uiManager.settings
                                newSettings.streamingEnabled = newValue
                                Task {
                                    await chatCoordinator.updateSettings(newSettings)
                                }
                            }
                        )
                    )
                }

                Section {
                    Button("Start New Conversation") {
                        Task {
                            await chatCoordinator.startNewSession()
                            dismiss()
                        }
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
