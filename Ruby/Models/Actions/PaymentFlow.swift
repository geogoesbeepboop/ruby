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
        print("🚀 [PaymentFlow] Initializing PaymentFlow ObservableObject")
        
        let paymentTool = PaymentTool()
        print("🔧 [PaymentFlow] Created PaymentTool: \(paymentTool.name)")
        
        session = LanguageModelSession(
            tools: [paymentTool],
            instructions: PaymentInstructions.sendZelle
        )
        print("📱 [PaymentFlow] LanguageModelSession initialized with PaymentTool")
        print("✅ [PaymentFlow] PaymentFlow ready for user interactions")
    }
    
    @MainActor
    func handlePaymentFlow() async {
        print("\n💳 [PaymentFlow] === PAYMENT WORKFLOW STARTED ===")
        print("🔄 [PaymentFlow] User clicked 'Send Payment' button")
        startProcessing()
        
        do {
            let prompt = Prompt("Initiate Zelle payment: Send $50.00 to john@example.com with memo 'Lunch money'")
            print("📝 [PaymentFlow] Created payment prompt for LanguageModelSession")
            print("🤖 [PaymentFlow] Sending prompt to Apple Foundation Models...")
            
            // First stream: Get payment details
            print("🔄 [PaymentFlow] PHASE 1: Streaming payment details from LanguageModelSession")
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
                currentPayment = partialPayment
            }
            print("Transcript for First stream: Get payment details: \(String(describing: session.transcript))")
            print("✅ [PaymentFlow] PHASE 1 COMPLETE: Payment details generated")
            
            // Second stream: Get payment result/confirmation
            let resultPrompt = Prompt("Complete the payment processing and provide confirmation details including confirmation number and updated balance")
            print("🔄 [PaymentFlow] PHASE 2: Streaming payment result from LanguageModelSession")
            
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
                paymentResult = partialPaymentResult
            }
            print("Transcript for Second stream: Get payment result/confirmation: \(String(describing: session.transcript))")
            print("✅ [PaymentFlow] PHASE 2 COMPLETE: Payment result generated")
            
        } catch {
            print("❌ [PaymentFlow] ERROR in payment workflow: \(error.localizedDescription)")
            setError("Payment failed: \(error.localizedDescription)")
        }
        
        print("✅ [PaymentFlow] === PAYMENT WORKFLOW COMPLETED ===\n")
        completeProcessing()
    }
    @MainActor
    func startProcessing() {
        print("🔄 [PaymentFlow] Setting isProcessing = true, clearing previous state")
        print("🧹 [PaymentFlow] Clearing currentPayment, paymentResult, errorMessage")
        isProcessing = true
        errorMessage = nil
        currentPayment = nil
        paymentResult = nil
    }
    
    @MainActor
    func completeProcessing() {
        print("✅ [PaymentFlow] Setting isProcessing = false - UI will hide loading state")
        isProcessing = false
    }
    
    @MainActor
    func setError(_ error: String) {
        print("❌ [PaymentFlow] Setting error state: \(error)")
        print("🔄 [PaymentFlow] Setting isProcessing = false - UI will show error")
        errorMessage = error
        isProcessing = false
    }
}
