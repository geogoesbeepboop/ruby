//
//  Action.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels

@Generable
struct Action {
    @Guide(description: "Type of banking action to perform")
    let type: ActionType
    @Guide(description: "Unique identifier for this action request")
    let requestId: String
    @Guide(description: "Timestamp when action was initiated in ISO8601 format")
    let initiatedAt: String
    
    @Generable
    enum ActionType: String, CaseIterable {
        case sendZelle, checkBalance
    }
}
