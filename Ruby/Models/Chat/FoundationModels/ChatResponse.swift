//
//  ChatResponse.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import FoundationModels

@Generable
struct ChatResponse {
    @Guide(description: "The main response content to the user's message")
    let content: String
    
    @Guide(description: "Emotional tone of the response")
    let tone: String
    
    @Guide(description:"Confidence level in the response accuracy with a range of 0.0 to 1.0")
    let confidence: Double
}
