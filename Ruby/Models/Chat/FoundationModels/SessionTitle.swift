//
//  SessionTitle.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import FoundationModels

@Generable
struct SessionTitle {
    @Guide(description: "A concise, descriptive title that captures the main topic or theme of the conversation (3-6 words max)")
    let title: String
    
    @Guide(description: "Confidence level in the title relevance", .range(0.0...1.0))
    let confidence: Double
}
