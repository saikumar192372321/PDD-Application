import SwiftUI

struct RazorpayCheckoutView: View {
    let amount: Double
    let userEmail: String
    let onPaymentComplete: (Bool) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var isProcessing = false
    @State private var showStatus = false
    @State private var paymentSuccess = false
    @State private var statusMessage = ""
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.title2)
                    Text("Razorpay Secure")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(20)
                .background(Color(red: 0.1, green: 0.3, blue: 0.8))
                .foregroundColor(.white)
                
                VStack(spacing: 30) {
                    if !showStatus {
                        VStack(spacing: 8) {
                            Text("PAYMENT AMOUNT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppColors.textSecondary)
                            Text("₹\(Int(amount))")
                                .font(.system(size: 36, weight: .black))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            PaymentFeatureRow(icon: "shield.check.fill", title: "100% Secure Transaction")
                            PaymentFeatureRow(icon: "bolt.fill", title: "Instant Order Confirmation")
                        }
                        
                        Button(action: createOrder) {
                            ZStack {
                                if isProcessing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("OPEN SECURE GATEWAY")
                                        .font(.system(size: 14, weight: .black))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.1, green: 0.3, blue: 0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                        
                        // Added Quick Simulation for Test Mode
                        Button(action: simulateSuccess) {
                            Text("SIMULATE SUCCESS (DEV ONLY)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppColors.secondary)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.top, -15)
                    } else {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(paymentSuccess ? Color.green : Color.red)
                                    .frame(width: 80, height: 80)
                                    .scaleEffect(animateGlow ? 1.2 : 1.0)
                                    .opacity(animateGlow ? 0.3 : 0.6)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateGlow)
                                
                                Image(systemName: paymentSuccess ? "checkmark" : "xmark")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .onAppear { animateGlow = true }
                            
                            VStack(spacing: 8) {
                                Text(paymentSuccess ? "PAYMENT SUCCESSFUL" : "PAYMENT FAILED")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(paymentSuccess ? .green : .red)
                                
                                Text(statusMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Button(action: {
                                if paymentSuccess {
                                    onPaymentComplete(true)
                                }
                                dismiss()
                            }) {
                                Text(paymentSuccess ? "CONTINUE TO ORDER" : "CLOSE")
                                    .font(.system(size: 14, weight: .black))
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 16)
                                    .background(AppColors.textPrimary)
                                    .foregroundColor(AppColors.surfaceLight)
                                    .cornerRadius(30)
                            }
                        }
                        .padding(.vertical, 40)
                    }
                    
                    if !showStatus && !isProcessing {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TEST CREDENTIALS")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.textSecondary)
                                .tracking(1)
                            
                            VStack(spacing: 8) {
                                DummyInfoRow(label: "Key ID", value: APIConfig.razorpayKeyID)
                                Divider()
                                DummyInfoRow(label: "Card", value: "4111 1111 1111 1111", isCopyable: true)
                                DummyInfoRow(label: "Expiry/CVV", value: "12/30 | 123")
                                DummyInfoRow(label: "OTP/UPI", value: "123456 | success@razorpay")
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(24)
                .background(AppColors.surfaceLight)
                
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 10))
                    Text("RAZORPAY TRUSTED GATEWAY")
                        .font(.system(size: 10, weight: .bold))
                    Spacer()
                }
                .padding(12)
                .background(Color.gray.opacity(0.05))
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
            }
            .frame(width: 320)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    // Step 1: Create Order on Backend
    private func createOrder() {
        isProcessing = true
        HapticManager.shared.trigger(.medium)
        
        guard let url = URL(string: APIConfig.createRazorpayOrder) else {
            handleError("Invalid API configuration")
            return
        }
        
        let body: [String: Any] = ["amount": amount]
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, status == "success",
                   let innerData = json["data"] as? [String: Any],
                   let orderID = innerData["order_id"] as? String {
                    
                    await MainActor.run {
                        launchRazorpay(orderID: orderID)
                    }
                } else {
                    handleError("Failed to initialize payment session")
                }
            } catch {
                handleError("Network connection failed")
            }
        }
    }
    
    // Step 2: Launch SDK
    private func launchRazorpay(orderID: String) {
        RazorpayPaymentHandler.shared.onPaymentSuccess = { paymentID in
            withAnimation {
                isProcessing = false
                paymentSuccess = true
                showStatus = true
                statusMessage = "Order verified successfully. Payment ID: \(paymentID)"
                HapticManager.shared.notify(.success)
            }
        }
        
        RazorpayPaymentHandler.shared.onPaymentError = { error in
            handleError(error)
        }
        
        RazorpayPaymentHandler.shared.startPayment(amount: amount, userEmail: userEmail, orderID: orderID)
    }
    
    private func simulateSuccess() {
        isProcessing = true
        HapticManager.shared.trigger(.medium)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isProcessing = false
                paymentSuccess = true
                showStatus = true
                statusMessage = "Payment Mocked Successfully (Sandbox). Ref: PAY_MOCK_\(Int.random(in: 1000...9999))"
                HapticManager.shared.notify(.success)
            }
        }
    }
    
    private func handleError(_ msg: String) {
        withAnimation {
            isProcessing = false
            paymentSuccess = false
            showStatus = true
            statusMessage = msg
            HapticManager.shared.notify(.error)
        }
    }
}

private struct DummyInfoRow: View {
    let label: String
    let value: String
    var isCopyable: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
            
            if isCopyable {
                Button(action: {
                    UIPasteboard.general.string = value
                    HapticManager.shared.trigger(.light)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 8))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

private struct PaymentFeatureRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(Color.black.opacity(0.02))
        .cornerRadius(10)
    }
}
// Keep the old name alias for compatibility with CartView for now
typealias RazorpayDummyView = RazorpayCheckoutView
