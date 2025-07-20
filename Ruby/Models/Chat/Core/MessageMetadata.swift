//
//  MessageMetadata.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation

struct MessageMetadata: Codable {
    let processingTime: TimeInterval?
    let tokens: Int?
    let confidence: Double?
    let tone: String?
    let category: String?
    let topics: [String]?
    let requiresFollowUp: Bool?
    
    init(
        processingTime: TimeInterval? = nil,
        tokens: Int? = nil,
        confidence: Double? = nil,
        tone: String? = nil,
        category: String? = nil,
        topics: [String]? = nil,
        requiresFollowUp: Bool? = nil
    ) {
        self.processingTime = processingTime
        self.tokens = tokens
        self.confidence = confidence
        self.tone = tone
        self.category = category
        self.topics = topics
        self.requiresFollowUp = requiresFollowUp
    }
}
