//
//  Balance.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import Foundation
import FoundationModels

@Generable
struct AccountBalance {
    @Guide(description: "Account identifier")
    let accountId: String
    @Guide(description: "Type of account")
    let accountType: AccountType
    @Guide(description: "Account display name")
    let accountName: String
    @Guide(description: "Current posted balance")
    let currentBalance: Double
    @Guide(description: "Available balance for transactions")
    let availableBalance: Double
    @Guide(description: "Total pending transactions amount")
    let pendingAmount: Double
    @Guide(description: "Account status")
    let status: AccountStatus
    @Guide(description: "Last updated timestamp in ISO8601 format")
    let lastUpdated: String
    
    @Generable
    enum AccountType: String, CaseIterable {
        case checking, savings, credit, investment, loan
    }
    
    @Generable
    enum AccountStatus: String, CaseIterable {
        case active, frozen, closed, restricted, suspended
    }

}

@Generable
struct CreditAccountBalance {
    @Guide(description: "Base account information")
    let baseAccount: AccountBalance
    @Guide(description: "Total credit limit")
    let creditLimit: Double
    @Guide(description: "Available credit remaining")
    let availableCredit: Double
    @Guide(description: "Minimum payment due")
    let minimumPaymentDue: Double
    @Guide(description: "Payment due date in ISO8601 format")
    let paymentDueDate: String?
    @Guide(description: "Current APR")
    let currentAPR: Double
}

@Generable
struct BalancesSummary {
    @Guide(description: "All user account balances")
    let accounts: [AccountBalance]
    @Guide(description: "Total liquid assets")
    let totalLiquidAssets: Double
    @Guide(description: "Total credit available")
    let totalAvailableCredit: Double
    @Guide(description: "Any account alerts or notices")
    let alerts: [String]
}
