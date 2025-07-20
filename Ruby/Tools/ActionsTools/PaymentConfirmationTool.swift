//
//  PaymentConfirmationTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/20/25.
//
import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class PaymentConfirmationTool: Tool {
    let name = "PaymentConfirmationTool"
    let description = "Use this for payment confirmations when users confirm or cancel a payment"
    
    @Generable
    struct Arguments {
        @Guide(description: "Whether the user confirmed (true) or cancelled (false) the payment")
        let confirmed: Bool
        @Guide(description: "The payment amount from the previous validation")
        let amount: Double
        @Guide(description: "The recipient from the previous validation")
        let recipient: String
        @Guide(description: "The payment method from the previous validation")
        let method: String
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        print("🔧 [PaymentConfirmationTool] Processing payment confirmation")
        print("   ✅ Confirmed: \(arguments.confirmed ? "Yes" : "No")")
        print("   💰 Amount: $\(String(format: "%.2f", arguments.amount))")
        print("   👤 Recipient: \(arguments.recipient)")
        
        if arguments.confirmed {
            // Simulate payment processing
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let confirmationNumber = generateConfirmationNumber()
            let transactionId = generateTransactionId()
            let newBalance = generateNewBalance()
            
            let result = """
            ✅ Payment Confirmed and Processed!
            
            💳 Transaction Details:
            - Amount: $\(String(format: "%.2f", arguments.amount))
            - Recipient: \(arguments.recipient)
            - Method: \(arguments.method)
            - Confirmation #: \(confirmationNumber)
            - Transaction ID: \(transactionId)
            - Status: Completed
            - Processed: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))
            
            💰 Account Update:
            - New balance: $\(String(format: "%.2f", newBalance))
            - Transaction fee: $0.00 (Zelle fee waived)
            
            📧 A confirmation email has been sent to your registered email address.
            
            Note: This is a simulated transaction for demonstration purposes.
            """
            
            print("✅ [PaymentConfirmationTool] Payment processed successfully")
            return ToolOutput(result)
            
        } else {
            let result = """
            ❌ Payment Cancelled
            
            Your payment of $\(String(format: "%.2f", arguments.amount)) to \(arguments.recipient) has been cancelled.
            
            No funds have been transferred.
            Your account balance remains unchanged.
            
            You can initiate a new payment anytime by saying something like "send $X to [recipient]".
            """
            
            print("❌ [PaymentConfirmationTool] Payment cancelled by user")
            return ToolOutput(result)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func generateConfirmationNumber() -> String {
        let numbers = (1...6).map { _ in Int.random(in: 0...9) }
        return "ZEL-" + numbers.map(String.init).joined()
    }
    
    private func generateTransactionId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        let randomNum = String(format: "%04d", Int.random(in: 1000...9999))
        return "TXN-\(dateString)-\(randomNum)"
    }
    
    private func generateNewBalance() -> Double {
        // Mock calculation - in real app would query actual balance
        return Double.random(in: 1000.0...5000.0)
    }
}
