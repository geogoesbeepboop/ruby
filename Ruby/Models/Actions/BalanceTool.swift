//
//  BalanceTool.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/18/25.
//
import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class BalanceTool: Tool {
    let name = "balanceRetriever"
    let description = "Retrieves current account balances, calculates totals, and checks for account alerts"
    
    @Generable
    struct Arguments {
        @Guide(description: "Types of accounts to include in balance check")
        let accountTypes: [String]
        @Guide(description: "Whether to include pending transactions in calculations")
        let includePending: Bool
        @Guide(description: "Whether to check for account alerts and notifications")
        let checkAlerts: Bool
    }
    
    func call(arguments: Arguments) async throws -> ToolOutput {
        print("[BalanceTool] Tool called with arguments: accountTypes=\(arguments.accountTypes), includePending=\(arguments.includePending), checkAlerts=\(arguments.checkAlerts)")
        
        // Simulate processing time
        try await Task.sleep(nanoseconds: 750_000_000) // 0.75 seconds
        
        // Hardcoded POC balance data
        let accountBalances = generateMockAccountBalances()
        let totalLiquidAssets = calculateTotalLiquidAssets(accountBalances)
        let availableCredit = calculateAvailableCredit()
        let alerts = arguments.checkAlerts ? generateMockAlerts() : []
        let pendingTransactions = arguments.includePending ? generateMockPendingTransactions() : []
        
        let result = """
        Account Balance Summary:
        
        💰 Account Balances:
        \(accountBalances.map { "- \($0)" }.joined(separator: "\n"))
        
        📊 Financial Overview:
        - Total Liquid Assets: $\(String(format: "%.2f", totalLiquidAssets))
        - Total Available Credit: $\(String(format: "%.2f", availableCredit))
        - Net Worth Impact: $\(String(format: "%.2f", totalLiquidAssets + availableCredit))
        
        \(pendingTransactions.isEmpty ? "" : "⏳ Pending Transactions:\n\(pendingTransactions.map { "- \($0)" }.joined(separator: "\n"))\n")
        
        \(alerts.isEmpty ? "✅ No account alerts" : "🚨 Account Alerts:\n\(alerts.map { "- \($0)" }.joined(separator: "\n"))")
        """
        
        print("[BalanceTool] Returning balance summary with \(accountBalances.count) accounts")
        return ToolOutput(result)
    }
    
    // MARK: - Private Helper Methods (Hardcoded POC Data)
    
    private func generateMockAccountBalances() -> [String] {
        print("[BalanceTool] Generating mock account balances")
        
        let accounts = [
            ("Primary Checking", Double.random(in: 1200.0...5000.0)),
            ("High-Yield Savings", Double.random(in: 8000.0...25000.0)),
            ("Investment Account", Double.random(in: 15000.0...75000.0)),
            ("Credit Card", -Double.random(in: 0.0...2500.0))
        ]
        
        return accounts.map { name, balance in
            let balanceStr = balance >= 0 ? 
                "$\(String(format: "%.2f", balance))" : 
                "-$\(String(format: "%.2f", abs(balance)))"
            return "\(name): \(balanceStr)"
        }
    }
    
    private func calculateTotalLiquidAssets(_ balances: [String]) -> Double {
        print("[BalanceTool] Calculating total liquid assets")
        // Mock calculation - in real app would parse actual balances
        return Double.random(in: 25000.0...100000.0)
    }
    
    private func calculateAvailableCredit() -> Double {
        print("[BalanceTool] Calculating available credit")
        return Double.random(in: 5000.0...15000.0)
    }
    
    private func generateMockAlerts() -> [String] {
        print("[BalanceTool] Generating mock alerts")
        
        let possibleAlerts = [
            "Low balance alert on checking account",
            "Credit card payment due in 3 days",
            "Unusual spending pattern detected",
            "Direct deposit processed successfully",
            "Investment account gained 2.3% this month"
        ]
        
        // Randomly return 0-2 alerts
        let alertCount = Int.random(in: 0...2)
        return Array(possibleAlerts.shuffled().prefix(alertCount))
    }
    
    private func generateMockPendingTransactions() -> [String] {
        print("[BalanceTool] Generating mock pending transactions")
        
        let transactions = [
            "Pending: Grocery Store -$84.50",
            "Pending: Gas Station -$45.20",
            "Pending: Online Purchase -$129.99",
            "Pending: Salary Deposit +$2,850.00"
        ]
        
        // Randomly return 0-3 pending transactions
        let transactionCount = Int.random(in: 0...3)
        return Array(transactions.shuffled().prefix(transactionCount))
    }
}