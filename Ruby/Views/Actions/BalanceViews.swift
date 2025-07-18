//
//  BalanceViews.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct BalanceLoadingView: View {
    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
            
            Text("Loading Account Balances...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

@available(iOS 26.0, *)
struct BalancesSummaryView: View {
    let balances: BalancesSummary.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                
                Text("Account Balances")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let lastUpdateString = balances.accounts?.first?.lastUpdated,
                   let lastUpdate = DateFormatter.iso8601.date(from: lastUpdateString) {
                    Text("Updated \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Summary Totals
            if let totalAssets = balances.totalLiquidAssets {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Liquid Assets")
                        .contentTransition(.opacity)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalAssets, specifier: "%.2f")")
                        .contentTransition(.opacity)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                )
            }
            
            // Individual Accounts
            if let accounts = balances.accounts {
                VStack(spacing: 12) {
                    ForEach(accounts, id: \.accountId) { account in
                        AccountBalanceRow(account: account)
                    }
                }
            }
            
            // Alerts
            if let alerts = balances.alerts, !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    ForEach(alerts, id: \.self) { alert in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text(alert)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Credit Summary
            if let totalCredit = balances.totalAvailableCredit, totalCredit > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Available Credit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(totalCredit, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
}

@available(iOS 26.0, *)
struct AccountBalanceRow: View {
    let account: AccountBalance.PartiallyGenerated
    
    var body: some View {
        VStack(spacing: 8) {
            // Account Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let accountName = account.accountName {
                        Text(accountName)
                            .contentTransition(.opacity)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    if let accountType = account.accountType {
                        Text(accountType.rawValue.capitalized)
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if let currentBalance = account.currentBalance {
                        Text("$\(currentBalance, specifier: "%.2f")")
                            .contentTransition(.opacity)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    if let status = account.status {
                        Text(status.rawValue.capitalized)
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(status == .active ? .green : .orange)
                    }
                }
            }
            
            // Balance Details
            VStack(spacing: 4) {
                if let availableBalance = account.availableBalance {
                    HStack {
                        Text("Available Balance:")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("$\(availableBalance, specifier: "%.2f")")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                if let pendingAmount = account.pendingAmount, pendingAmount != 0 {
                    HStack {
                        Text("Pending Transactions:")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("$\(pendingAmount, specifier: "%.2f")")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                if let accountId = account.accountId {
                    HStack {
                        Text("Account ID:")
                            .contentTransition(.opacity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(accountId)
                            .contentTransition(.opacity)
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
        )
    }
}
