//
//  ChatState.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation

enum ChatState: Equatable {
    case activeChat
    case voiceListening
//    case aiThinking
    case streaming
    case error(String)
    
    static func == (lhs: ChatState, rhs: ChatState) -> Bool {
      switch (lhs, rhs) {
      case (.activeChat, .activeChat):
        return true
      case (.voiceListening, .voiceListening):
        return true
//      case (.aiThinking, .aiThinking):
//        return true
      case (.streaming, .streaming):
        return true
      case (.error(let lhsError), .error(let rhsError)):
          return lhsError.isEqual(rhsError)
      default:
        return false
      }
    }
}
