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
    let name = "TransactionsTool"
    let description = "Use this tool to handle and validate user transactions"
    
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
        print("🔧 [PaymentTool] Starting payment validation")
        print("   💰 Amount: $\(String(format: "%.2f", arguments.amount))")
        print("   👤 Recipient: \(arguments.recipient)")
        print("   💳 Method: \(arguments.method)")
        if let memo = arguments.memo {
            print("   📝 Memo: \(memo)")
        }
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Hardcoded POC validation logic
        let isValidRecipient = validateRecipient(arguments.recipient)
        let fees = calculateFees(amount: arguments.amount, method: arguments.method)
        let processingTime = getProcessingTime(method: arguments.method)
        let accountStatus = checkAccountStatus()
        let remainingLimit = getRemainingDailyLimit()
        
        let result = """
        Payment Validation Results:
        
        💰 Payment Details:
        - Amount: $\(String(format: "%.2f", arguments.amount))
        - Recipient: \(arguments.recipient)
        - Method: \(arguments.method)
        \(arguments.memo != nil ? "- Memo: \(arguments.memo!)" : "")
        
        🔒 Security Check:
        - Recipient validation: \(isValidRecipient ? "✅ Valid" : "❌ Invalid")
        - Processing fee: $\(String(format: "%.2f", fees))
        - Estimated processing time: \(processingTime)
        - Account status: \(accountStatus)
        - Daily limit remaining: $\(String(format: "%.2f", remainingLimit))
        - Security verification: ✅ Passed
        
        ⚠️ CONFIRMATION REQUIRED:
        This payment is ready to process. To complete this transaction, please respond with "CONFIRM PAYMENT" or "CANCEL PAYMENT".
        
        Note: This is a simulated payment for demonstration purposes.
        """
        
        print("✅ [PaymentTool] Validation complete - returning results to LanguageModelSession")
        return ToolOutput(result)
    }
    
    // MARK: - Private Helper Methods (Hardcoded POC Data)
    
    private func validateRecipient(_ recipient: String) -> Bool {
        // Mock validation - email format or phone format
        let isValid = recipient.contains("charlie") || recipient.contains("@") || recipient.contains("+") || recipient.allSatisfy { $0.isNumber }
        print("   🔍 Recipient validation: \(isValid ? "✅ Valid" : "❌ Invalid")")
        return isValid
    }
    
    private func calculateFees(amount: Double, method: String) -> Double {
        let fee = switch method.lowercased() {
        case "zelle":
            0.0 // Zelle typically free
        case "wire":
            25.0
        case "ach":
            1.50
        default:
            2.50
        }
        print("   💵 Fee calculation: $\(String(format: "%.2f", fee)) for \(method)")
        return fee
    }
    
    private func getProcessingTime(method: String) -> String {
        let time = switch method.lowercased() {
        case "zelle":
            "Instant (typically within minutes)"
        case "wire":
            "Same business day"
        case "ach":
            "1-3 business days"
        default:
            "2-3 business days"
        }
        print("   ⏱️ Processing time: \(time)")
        return time
    }
    
    private func checkAccountStatus() -> String {
        let statuses = ["Active - Good Standing", "Active - Standard", "Active - Premium Member"]
        let status = statuses.randomElement() ?? "Active"
        print("   🏦 Account status: \(status)")
        return status
    }
    
    private func getRemainingDailyLimit() -> Double {
        let limit = Double.random(in: 500.0...2500.0)
        print("   📊 Daily limit remaining: $\(String(format: "%.2f", limit))")
        return limit
    }
}
