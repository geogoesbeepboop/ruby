//
//  MicButton.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct MicButton: View {
    let isRecording: Bool
    let startVoiceRecording: () -> Void

    var body: some View {
        Button(action: startVoiceRecording) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                .font(.title3)
                .foregroundStyle(
                    isRecording
                        ? AnyShapeStyle(.red)
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "fc9afb"), Color(hex: "9b6cb0"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .accessibilityLabel(
            isRecording ? "Stop recording" : "Start voice recording"
        )
    }
}
