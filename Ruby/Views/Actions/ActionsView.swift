//
//  ActionsView.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct ActionsView: View {
    @StateObject private var paymentFlow = PaymentFlow()
    @StateObject private var balanceInfo = BalanceInfo()
    @State private var triggerPayment = false
    @State private var triggerBalance = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with material effect matching app theme
                MaterialBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Banking Actions")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.brandSecondary)
                            
                            Text("Trigger banking workflows with AI assistance")
                                .font(.subheadline)
                                .foregroundColor(.brandSecondary)
                        }
                        .padding(.top, 20)
                        
                        // Action Buttons
                        VStack(spacing: 20) {
                            ActionButton(
                                title: "Send Payment",
                                subtitle: "Send money via Zelle",
                                icon: "dollarsign.circle.fill",
                                isLoading: paymentFlow.isProcessing
                            ) {
                                print("\n🔘 [ActionsView] === USER INTERACTION: PAYMENT BUTTON TAPPED ===")
                                print("🔄 [ActionsView] Setting triggerPayment = true to activate .task")
                                triggerPayment = true
                            }
                            
                            ActionButton(
                                title: "Check Balances",
                                subtitle: "View account balances",
                                icon: "creditcard.fill",
                                isLoading: balanceInfo.isLoading
                            ) {
                                print("\n🔘 [ActionsView] === USER INTERACTION: BALANCE BUTTON TAPPED ===")
                                print("🔄 [ActionsView] Setting triggerBalance = true to activate .task")
                                triggerBalance = true
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Results Section
                        VStack(spacing: 20) {
                            // Payment Flow Results
                            if paymentFlow.isProcessing {
                                PaymentProgressView(paymentFlow: paymentFlow)
                                    .onAppear { print("🔄 [ActionsView] UI UPDATE: Displaying PaymentProgressView") }
                            }
                            
                            if let payment = paymentFlow.currentPayment {
                                PaymentDetailsView(payment: payment)
                                    .onAppear { print("📊 [ActionsView] UI UPDATE: Displaying PaymentDetailsView") }
                            }
                            
                            if let result = paymentFlow.paymentResult {
                                PaymentResultView(result: result)
                                    .onAppear { print("✅ [ActionsView] UI UPDATE: Displaying PaymentResultView") }
                            }
                            
                            if let errorMessage = paymentFlow.errorMessage {
                                ErrorView(message: errorMessage)
                                    .onAppear { print("❌ [ActionsView] UI UPDATE: Displaying payment error: \(errorMessage)") }
                            }
                            
                            // Balance Flow Results
                            if balanceInfo.isLoading {
                                BalanceLoadingView()
                                    .onAppear { print("🔄 [ActionsView] UI UPDATE: Displaying BalanceLoadingView") }
                            }
                            
                            if let balancesSummary = balanceInfo.balancesSummary {
                                BalancesSummaryView(balances: balancesSummary)
                                    .onAppear { print("📊 [ActionsView] UI UPDATE: Displaying BalancesSummaryView") }
                            }

                            if let errorMessage = balanceInfo.errorMessage {
                                ErrorView(message: errorMessage)
                                    .onAppear { print("❌ [ActionsView] UI UPDATE: Displaying balance error: \(errorMessage)") }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("📱 [ActionsView] ActionsView appeared - PaymentFlow and BalanceInfo @StateObjects ready")
        }
        .task(id: triggerPayment) {
            guard triggerPayment else { return }
            print("🚀 [ActionsView] Payment .task triggered - calling PaymentFlow.handlePaymentFlow()")
            await paymentFlow.handlePaymentFlow()
            print("✅ [ActionsView] Payment .task completed - resetting triggerPayment = false")
            triggerPayment = false
        }
        .task(id: triggerBalance) {
            guard triggerBalance else { return }
            print("🚀 [ActionsView] Balance .task triggered - calling BalanceInfo.handleBalanceCheck()")
            await balanceInfo.handleBalanceCheck()
            print("✅ [ActionsView] Balance .task completed - resetting triggerBalance = false")
            triggerBalance = false
        }
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.brandPrimary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
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
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

//@available(iOS 26.0, *)
//#Preview {
//    ActionsView()
//}
