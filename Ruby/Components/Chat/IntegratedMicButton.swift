//
//  IntegratedMicButton.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/14/25.
//
import SwiftUI

struct IntegratedMicButton: View {
    let isRecording: Bool
    let startVoiceRecording: () -> Void
    let stopVoiceRecording: () -> Void

    var body: some View {
        Button(action: {
            if isRecording {
                stopVoiceRecording()
            } else {
                startVoiceRecording()
            }
        }) {
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
                .frame(width: 32, height: 32)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .accessibilityLabel(
            isRecording ? "Stop recording" : "Start voice recording"
        )
    }
}
