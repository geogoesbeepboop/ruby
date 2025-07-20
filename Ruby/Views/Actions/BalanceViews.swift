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

// MARK: - Dismissable Wrapper Views

@available(iOS 26.0, *)
struct DismissableBalanceView<Content: View>: View {
    let content: Content
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isVisible = true
    
    init(@ViewBuilder content: () -> Content, onDismiss: @escaping () -> Void) {
        self.content = content()
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        if isVisible {
            ZStack(alignment: .topTrailing) {
                content
                    .offset(dragOffset)
                    .opacity(1.0 - abs(dragOffset.width) / CGFloat(300))
                    .scaleEffect(1 - abs(dragOffset.width) / 1000)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if abs(value.translation.width) > 100 || abs(value.predictedEndTranslation.width) > 200 {
                                        // Dismiss with animation
                                        dragOffset = CGSize(width: value.translation.width > 0 ? 400 : -400, height: 0)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            dismissPanel()
                                        }
                                    } else {
                                        // Snap back
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
                
                // X button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        dismissPanel()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(8)
                .buttonStyle(PlainButtonStyle())
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        }
    }
    
    private func dismissPanel() {
        isVisible = false
        onDismiss()
    }
}

// MARK: - Previews

//@available(iOS 26.0, *)
//#Preview("Dismissable Balance Views") {
//    ScrollView {
//        VStack(spacing: 20) {
//            DismissableBalanceView(
//                content: {
//                    BalanceLoadingView()
//                },
//                onDismiss: { print("Balance loading dismissed") }
//            )
//            
//            DismissableBalanceView(
//                content: {
//                    BalancesSummaryView(balances: BalancesSummary.PartiallyGenerated(
//                        totalLiquidAssets: 5450.75,
//                        totalAvailableCredit: 15000.00,
//                        accounts: [
//                            AccountBalance.PartiallyGenerated(
//                                accountName: "Checking Account",
//                                accountType: .checking,
//                                currentBalance: 2500.50,
//                                availableBalance: 2500.50,
//                                accountId: "CHK001",
//                                status: .active,
//                                lastUpdated: "2024-01-15T10:30:00Z",
//                                pendingAmount: 0
//                            )
//                        ],
//                        alerts: ["Low balance alert for Savings Account"]
//                    ))
//                },
//                onDismiss: { print("Balance summary dismissed") }
//            )
//        }
//        .padding()
//    }
//}
