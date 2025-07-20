//
//  BalanceInfo.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels
import Combine

final class BalanceInfo: ObservableObject {
    let session: LanguageModelSession
    @Published var balancesSummary: BalancesSummary.PartiallyGenerated?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?
    
    init() {
        print("🚀 [BalanceInfo] Initializing BalanceInfo ObservableObject")
        
        let balanceTool = BalanceTool()
        print("🔧 [BalanceInfo] Created BalanceTool: \(balanceTool.name)")
        
        self.session = LanguageModelSession(
            tools: [balanceTool],
            instructions: BalanceInstructions.comprehensive
        )
        print("📱 [BalanceInfo] LanguageModelSession initialized with BalanceTool")
        print("✅ [BalanceInfo] BalanceInfo ready for user interactions")
    }

    @MainActor
    func handleBalanceCheck() async {
        print("\n💰 [BalanceInfo] === BALANCE WORKFLOW STARTED ===")
        print("🔄 [BalanceInfo] User clicked 'Check Balances' button")
        startLoading()
        
        do {
            let prompt = Prompt("What's my balance in my primary bank account")
            print("📝 [BalanceInfo] Created balance prompt for LanguageModelSession")
            print("🤖 [BalanceInfo] Sending prompt to Apple Foundation Models...")
            
            print("🔄 [BalanceInfo] Streaming balance data from LanguageModelSession")
            let balanceSummaryStream = session.streamResponse(
                to: prompt,
                generating: BalancesSummary.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 1.0,
//                    maximumResponseTokens: 600
                )
            )
            
            for try await partialBalanceSummary in balanceSummaryStream {
                balancesSummary = partialBalanceSummary
            }
            print("✅ [BalanceInfo] Balance summary stream completed")
            print("Transcript for balance info stream: Get payment details: \(String(describing: session.transcript))")
            lastRefreshDate = Date()
            print("📅 [BalanceInfo] Updated last refresh date: \(lastRefreshDate!)")
            
        } catch {
            print("❌ [BalanceInfo] ERROR in balance workflow: \(error.localizedDescription)")
            setError("Balance check failed: \(error.localizedDescription)")
        }
        
        print("✅ [BalanceInfo] === BALANCE WORKFLOW COMPLETED ===\n")
        completeLoading()
    }
    
    @MainActor
    func startLoading() {
        print("🔄 [BalanceInfo] Setting isLoading = true, clearing previous state")
        print("🧹 [BalanceInfo] Clearing balancesSummary, errorMessage")
        isLoading = true
        errorMessage = nil
    }
    
    @MainActor
    func completeLoading() {
        print("✅ [BalanceInfo] Setting isLoading = false - UI will hide loading state")
        isLoading = false
    }
    
    @MainActor
    func setError(_ error: String) {
        print("❌ [BalanceInfo] Setting error state: \(error)")
        print("🔄 [BalanceInfo] Setting isLoading = false - UI will show error")
        errorMessage = error
        isLoading = false
    }
}
