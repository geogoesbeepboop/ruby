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
            
            if let payment = paymentFlow.currentPayment {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Amount:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(payment.amount, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("To:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(payment.to)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(payment.status.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    HStack {
                        Text("Transaction ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(payment.transactionId)
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
                DetailRow(label: "Amount", value: "$\(payment.amount)")
                DetailRow(label: "Recipient", value: payment.to)
                DetailRow(label: "From Account", value: payment.fromAccount)
                DetailRow(label: "Memo", value: payment.memo)
                DetailRow(label: "Method", value: payment.method.rawValue.capitalized)
                DetailRow(label: "Fees", value: "$\(payment.fees)")
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confirmation Number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(result.confirmationNumber)
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundColor(.green)
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    DetailRow(label: "New Account Balance", value: "$\(result.newBalance)")
                    DetailRow(label: "Estimated Completion", value: DateFormatter.iso8601.date(from: result.estimatedCompletion)?.formatted(date: .abbreviated, time: .shortened))
                    DetailRow(label: "Amount Sent", value: "$\(result.payment.amount)")
                    DetailRow(label: "Sent To", value: result.payment.to)
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
