//
//  Payment.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels

@Generable
struct Payment:Equatable {
    @Guide(description: "Unique payment transaction ID")
    let transactionId: String
    @Guide(description: "Recipient identifier (email, phone, account)")
    let to: String
    @Guide(description: "Source account identifier")
    let fromAccount: String
    @Guide(description: "Payment amount in dollars", .range(0.01...10000.0))
    let amount: Double
    @Guide(description: "Optional payment memo or description")
    let memo: String?
    @Guide(description: "Scheduled send date in ISO8601 format")
    let sendDate: String
    @Guide(description: "Current payment status")
    let status: PaymentStatus
    @Guide(description: "Any applicable fees")
    let fees: Double?
    @Guide(description: "Payment method used")
    let method: PaymentMethod
    
    @Generable
    enum PaymentStatus: String, CaseIterable {
        case initiated, validating, pending, processing, completed, failed, cancelled, refunded
    }

    @Generable
    enum PaymentMethod: String, CaseIterable {
        case zelle, ach, wire, instantTransfer
    }
}

@Generable
struct PaymentResult: Equatable {
    @Guide(description: "Completed payment details")
    let payment: Payment
    @Guide(description: "Final confirmation number")
    let confirmationNumber: String
    @Guide(description: "Updated account balance after payment")
    let newBalance: Double
    @Guide(description: "Estimated completion time in ISO8601 format")
    let estimatedCompletion: String
    
    static func == (lhs: PaymentResult, rhs: PaymentResult) -> Bool {
        return lhs.payment == rhs.payment &&
               lhs.confirmationNumber == rhs.confirmationNumber &&
               lhs.newBalance == rhs.newBalance &&
               lhs.estimatedCompletion == rhs.estimatedCompletion
    }
}
