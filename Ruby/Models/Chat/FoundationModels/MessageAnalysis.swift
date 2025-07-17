//
//  MessageAnalysis.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import FoundationModels

@Generable
struct MessageAnalysis {
    @Guide(description: "The intent category of the message such as question, request, conversation, command, and greeting")
    let intent: String
    
    @Guide(description: "Emotional sentiment such as positive, neutral, negative")
    let sentiment: String
    
    @Guide(description: "Required response length such as brief, detailed or comprehensive")
    let responseLength: String
    
    @Guide(description: "Whether the message requires tool usage")
    let requiresTools: Bool
}
