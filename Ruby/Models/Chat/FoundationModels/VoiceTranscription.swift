//
//  VoiceTranscription.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import FoundationModels

@Generable
struct VoiceTranscription {
    @Guide(description: "The transcribed text from voice input")
    let text: String
    
    @Guide(description: "Confidence level of transcription accuracy", .range(0.0...1.0))
    let confidence: Double
    
    @Guide(description: "Detected language code (e.g., 'en-US')")
    let languageCode: String
}
