//
//  PaymentFlow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels

@Observable
@MainActor
final class PaymentFlow {
    let session: LanguageModelSession
    var currentPayment: Payment.PartiallyGenerated?
    var paymentResult: PaymentResult.PartiallyGenerated?
    var isProcessing = false
    var errorMessage: String?
    
    init() {
//        let options = GenerationOptions(
//            temperature: 0.1,
//            maximumResponseTokens: 500
//        )
        session = LanguageModelSession(
            tools: [],
            instructions: PaymentInstructions.sendZelle
        )
    }
    
    func handlePaymentFlow() async {
        startProcessing()
        
        do {
            let prompt = Prompt("Initiate Zelle payment: Send $50.00 to john@example.com with memo 'Lunch money'")
            
            // First stream: Get payment details
            var paymentStream = session.streamResponse(
                to: prompt,
                generating: Payment.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
//                    sampling: .greedy,
                    temperature: 0.1,
                    maximumResponseTokens: 300
                )
            )
            for try await partialPayment in paymentStream {
                currentPayment = partialPayment
            }
            
            // Second stream: Get payment result/confirmation
            let resultPrompt = Prompt("Complete the payment processing and provide confirmation details including confirmation number and updated balance")
            
            let paymentResultStream = session.streamResponse(
                to: resultPrompt,
                generating: PaymentResult.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
//                    sampling: .greedy,
                    temperature: 0.0,
                    maximumResponseTokens: 400
                )
            )
            for try await partialPaymentResult in paymentResultStream {
                paymentResult = partialPaymentResult
            }
        } catch {
            setError("Payment failed: \(error.localizedDescription)")
        }
        
        completeProcessing()
    }
    func startProcessing() {
        isProcessing = true
        errorMessage = nil
        currentPayment = nil
        paymentResult = nil
    }
    
    func completeProcessing() {
        isProcessing = false
    }
    
    func setError(_ error: String) {
        errorMessage = error
        isProcessing = false
    }
}
