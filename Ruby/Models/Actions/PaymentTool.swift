//
//  PaymentTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class PaymentTool: Tool {
    let name = "paymentProcessor"
    let description = "Validates payment details, calculates fees, and provides payment processing information"
    
    @Generable
    struct Arguments {
        @Guide(description: "The payment amount to validate and process")
        let amount: Double
        @Guide(description: "The recipient identifier (email, phone, account)")
        let recipient: String
        @Guide(description: "The payment method to use")
        let method: String
        @Guide(description: "Optional memo or description for the payment")
        let memo: String?
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[PaymentTool] Tool called with arguments: amount=\(arguments.amount), recipient=\(arguments.recipient), method=\(arguments.method)")
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Hardcoded POC validation logic
        let isValidRecipient = validateRecipient(arguments.recipient)
        let fees = calculateFees(amount: arguments.amount, method: arguments.method)
        let processingTime = getProcessingTime(method: arguments.method)
        let accountStatus = checkAccountStatus()
        
        let result = """
        Payment Validation Results:
        - Recipient validation: \(isValidRecipient ? "✅ Valid" : "❌ Invalid")
        - Processing fee: $\(String(format: "%.2f", fees))
        - Estimated processing time: \(processingTime)
        - Account status: \(accountStatus)
        - Daily limit remaining: $\(String(format: "%.2f", getRemainingDailyLimit()))
        - Security verification: ✅ Passed
        """
        
        print("[PaymentTool] Returning validation results: \(result)")
        return ToolOutput(result)
    }
    
    // MARK: - Private Helper Methods (Hardcoded POC Data)
    
    private func validateRecipient(_ recipient: String) -> Bool {
        print("[PaymentTool] Validating recipient: \(recipient)")
        // Mock validation - email format or phone format
        return recipient.contains("@") || recipient.contains("+") || recipient.allSatisfy { $0.isNumber }
    }
    
    private func calculateFees(amount: Double, method: String) -> Double {
        print("[PaymentTool] Calculating fees for amount: \(amount), method: \(method)")
        switch method.lowercased() {
        case "zelle":
            return 0.0 // Zelle typically free
        case "wire":
            return 25.0
        case "ach":
            return 1.50
        default:
            return 2.50
        }
    }
    
    private func getProcessingTime(method: String) -> String {
        print("[PaymentTool] Getting processing time for method: \(method)")
        switch method.lowercased() {
        case "zelle":
            return "Instant (typically within minutes)"
        case "wire":
            return "Same business day"
        case "ach":
            return "1-3 business days"
        default:
            return "2-3 business days"
        }
    }
    
    private func checkAccountStatus() -> String {
        print("[PaymentTool] Checking account status")
        let statuses = ["Active - Good Standing", "Active - Standard", "Active - Premium Member"]
        return statuses.randomElement() ?? "Active"
    }
    
    private func getRemainingDailyLimit() -> Double {
        print("[PaymentTool] Getting remaining daily limit")
        return Double.random(in: 500.0...2500.0)
    }
}