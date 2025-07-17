//
//  UserFriendlyErrorMessage.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import FoundationModels

@Generable
struct UserFriendlyErrorMessage {
    @Guide(description: "A warm, conversational message explaining why the AI can't fulfill the request, written as if the AI is speaking directly to the user")
    let message: String
    
    @Guide(description: "A helpful suggestion for what the user could try instead, if applicable")
    let suggestion: String?
    
    @Guide(description: "The tone of the message: apologetic, helpful, encouraging, or informative")
    let tone: String
}
