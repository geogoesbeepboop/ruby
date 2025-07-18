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
        print("[BalanceInfo] Initializing BalanceInfo")
        
        let balanceTool = BalanceTool()
        print("[BalanceInfo] Created BalanceTool: \(balanceTool.name)")
        
        self.session = LanguageModelSession(
            tools: [balanceTool],
            instructions: BalanceInstructions.comprehensive
        )
        print("[BalanceInfo] LanguageModelSession initialized with BalanceTool")
    }

    @MainActor
    func handleBalanceCheck() async {
        print("[BalanceInfo] Starting balance check")
        startLoading()
        
        do {
            let prompt = Prompt("Retrieve comprehensive account balances and summary for all user accounts including checking, savings, and credit accounts")
            print("[BalanceInfo] Created balance check prompt: \(prompt)")
            
            print("[BalanceInfo] Starting balance summary stream")
            let balanceSummaryStream = session.streamResponse(
                to: prompt,
                generating: BalancesSummary.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
                    temperature: 0.0,
                    maximumResponseTokens: 600
                )
            )
            
            for try await partialBalanceSummary in balanceSummaryStream {
                print("[BalanceInfo] Received partial balance summary: \(partialBalanceSummary)")
                balancesSummary = partialBalanceSummary
            }
            print("[BalanceInfo] Balance summary stream completed")
            
            lastRefreshDate = Date()
            print("[BalanceInfo] Updated last refresh date: \(lastRefreshDate!)")
            
        } catch {
            print("[BalanceInfo] Error occurred: \(error.localizedDescription)")
            setError("Balance check failed: \(error.localizedDescription)")
        }
        
        print("[BalanceInfo] Balance check completed")
        completeLoading()
    }
    
    @MainActor
    func startLoading() {
        print("[BalanceInfo] Starting loading - clearing previous state")
        isLoading = true
        errorMessage = nil
    }
    
    @MainActor
    func completeLoading() {
        print("[BalanceInfo] Completing loading")
        isLoading = false
    }
    
    @MainActor
    func setError(_ error: String) {
        print("[BalanceInfo] Setting error: \(error)")
        errorMessage = error
        isLoading = false
    }
}
