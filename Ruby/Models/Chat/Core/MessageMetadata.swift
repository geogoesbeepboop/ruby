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
}
