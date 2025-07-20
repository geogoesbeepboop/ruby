//
//  PaymentViews.swift
//  Ruby
//
//  Created by George Andrade-Munoz on 7/17/25.
//
import SwiftUI

@available(iOS 26.0, *)
struct PaymentProgressView: View {
    let paymentFlow: PaymentFlow
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                Text("Processing Payment...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            if let payment = paymentFlow.currentPayment,
               let paymentAmount = payment.amount,
               let paymentTo = payment.to,
               let paymentStatus = payment.status?.rawValue.capitalized,
               let paymentTransactionId = payment.transactionId 
            {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Amount:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(paymentAmount, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("To:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(paymentTo)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(paymentStatus)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Transaction ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(paymentTransactionId)
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

@available(iOS 26.0, *)
struct PaymentDetailsView: View {
    let payment: Payment.PartiallyGenerated
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Payment Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                if let amount = payment.amount {
                    DetailRow(label: "Amount", value: "$\(amount)")
                }
                if let to = payment.to {
                    DetailRow(label: "Recipient", value: to)
                }
                if let fromAccount = payment.fromAccount {
                    DetailRow(label: "From Account", value: fromAccount)
                }
                if let memo = payment.memo {
                    DetailRow(label: "Memo", value: memo)
                }
                if let method = payment.method {
                    DetailRow(label: "Method", value: method.rawValue.capitalized)
                }
                if let fees = payment.fees {
                    DetailRow(label: "Fees", value: "$\(fees)")
                }
            }
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
struct PaymentResultView: View {
    let result: PaymentResult.PartiallyGenerated
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Payment Completed")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let confirmationNumber = result.confirmationNumber {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Confirmation Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(confirmationNumber)
                            .font(.title3)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    if let newBalance = result.newBalance {
                        DetailRow(label: "New Account Balance", value: "$\(newBalance)")
                    }
                    if let estimatedCompletion = result.estimatedCompletion,
                       let date = DateFormatter.iso8601.date(from: estimatedCompletion) {
                        DetailRow(label: "Estimated Completion", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let payment = result.payment,
                       let amount = payment.amount {
                        DetailRow(label: "Amount Sent", value: "$\(amount)")
                    }
                    if let payment = result.payment,
                       let to = payment.to {
                        DetailRow(label: "Sent To", value: to)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.easeInOut, value: result)
    }
}

// MARK: - Dismissable Wrapper Views

@available(iOS 26.0, *)
struct DismissablePaymentView<Content: View>: View {
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

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Previews

//@available(iOS 26.0, *)
//#Preview("Dismissable Payment Views") {
//    ScrollView {
//        VStack(spacing: 20) {
//            DismissablePaymentView(
//                content: {
//                    PaymentProgressView(paymentFlow: PaymentFlow())
//                },
//                onDismiss: { print("Payment progress dismissed") }
//            )
//            
//            DismissablePaymentView(
//                content: {
//                    PaymentResultView(result: PaymentResult.PartiallyGenerated(
//                        confirmationNumber: "PAY123456789",
//                        newBalance: 1500.75,
//                        estimatedCompletion: "2024-01-15T14:30:00Z",
//                        payment: nil
//                    ))
//                },
//                onDismiss: { print("Payment result dismissed") }
//            )
//        }
//        .padding()
//    }
//}
