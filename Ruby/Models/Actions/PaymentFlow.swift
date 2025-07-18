//
//  PaymentFlow.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels
import Combine

final class PaymentFlow: ObservableObject {
    let session: LanguageModelSession
    @Published var currentPayment: Payment.PartiallyGenerated?
    @Published var paymentResult: PaymentResult.PartiallyGenerated?
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    init() {
        print("[PaymentFlow] Initializing PaymentFlow")
        
        let paymentTool = PaymentTool()
        print("[PaymentFlow] Created PaymentTool: \(paymentTool.name)")
        
        session = LanguageModelSession(
            tools: [paymentTool],
            instructions: PaymentInstructions.sendZelle
        )
        print("[PaymentFlow] LanguageModelSession initialized with PaymentTool")
    }
    
    @MainActor
    func handlePaymentFlow() async {
        print("[PaymentFlow] Starting payment flow")
        startProcessing()
        
        do {
            let prompt = Prompt("Initiate Zelle payment: Send $50.00 to john@example.com with memo 'Lunch money'")
            print("[PaymentFlow] Created payment prompt: \(prompt)")
            
            // First stream: Get payment details
            print("[PaymentFlow] Starting payment details stream")
            let paymentStream = session.streamResponse(
                to: prompt,
                generating: Payment.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.1,
                    maximumResponseTokens: 300
                )
            )
            
            for try await partialPayment in paymentStream {
                print("[PaymentFlow] Received partial payment: \(partialPayment)")
                currentPayment = partialPayment
            }
            print("[PaymentFlow] Payment details stream completed")
            
            // Second stream: Get payment result/confirmation
            let resultPrompt = Prompt("Complete the payment processing and provide confirmation details including confirmation number and updated balance")
            print("[PaymentFlow] Starting payment result stream")
            
            let paymentResultStream = session.streamResponse(
                to: resultPrompt,
                generating: PaymentResult.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.0,
                    maximumResponseTokens: 400
                )
            )
            
            for try await partialPaymentResult in paymentResultStream {
                print("[PaymentFlow] Received partial payment result: \(partialPaymentResult)")
                paymentResult = partialPaymentResult
            }
            print("[PaymentFlow] Payment result stream completed")
            
        } catch {
            print("[PaymentFlow] Error occurred: \(error.localizedDescription)")
            setError("Payment failed: \(error.localizedDescription)")
        }
        
        print("[PaymentFlow] Payment flow completed")
        completeProcessing()
    }
    @MainActor
    func startProcessing() {
        print("[PaymentFlow] Starting processing - clearing previous state")
        isProcessing = true
        errorMessage = nil
        currentPayment = nil
        paymentResult = nil
    }
    
    @MainActor
    func completeProcessing() {
        print("[PaymentFlow] Completing processing")
        isProcessing = false
    }
    
    @MainActor
    func setError(_ error: String) {
        print("[PaymentFlow] Setting error: \(error)")
        errorMessage = error
        isProcessing = false
    }
}
