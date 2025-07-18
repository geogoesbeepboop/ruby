//
//  BalanceInfo.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels

@Observable
@MainActor
final class BalanceInfo {
    let session: LanguageModelSession
    var balancesSummary: BalancesSummary.PartiallyGenerated?
    var isLoading = false
    var errorMessage: String?
    var lastRefreshDate: Date?
    
    init() {
//        let options = GenerationOptions(
//            sampling: .default,
//            temperature: 0.0,  // Zero for factual financial data
//            maximumResponseTokens: 800
//        )
        
        self.session = LanguageModelSession(
            tools: [],
            instructions: BalanceInstructions.comprehensive
        )
    }

    func handleBalanceCheck() async {
        do {
            let prompt = Prompt("Retrieve comprehensive account balances and summary for all user accounts including checking, savings, and credit accounts")
            
            let balanceSummaryStream = session.streamResponse(
                to: prompt,
                generating: BalancesSummary.self,
                includeSchemaInPrompt: true,
                options: GenerationOptions(
//                    sampling: .greedy,
                    temperature: 0.0,
                    maximumResponseTokens: 600
                )
            )
            for try await partialBalanceSummary in balanceSummaryStream {
                balancesSummary = partialBalanceSummary
            }
        } catch {
            print("Balance check failed: \(error.localizedDescription)")
        }
    }
}
