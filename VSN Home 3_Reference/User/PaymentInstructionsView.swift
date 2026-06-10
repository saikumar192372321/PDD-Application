import SwiftUI

struct PaymentInstructionsView: View {
    let orderTotal: Double
    let method: PaymentMethod
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var merchantUPIID: String = "vsnwholesale@upi" // Fetched live from server
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                header
                instructions
                Spacer()
                actionButtons
            }
            .padding(20)
            .navigationTitle("Payment Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .background(backgroundColor.ignoresSafeArea())
        }
        .hidesTabBar()
        .onAppear { fetchMerchantUPIID() }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount Due")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(secondaryTextColor)
            Text("₹\(Int(orderTotal))")
                .font(.system(size: 34, weight: .black))
                .foregroundStyle(primaryColor)
        }
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(methodTitle, systemImage: methodIcon)
                .font(.system(size: 16, weight: .bold))
            Text(methodDetails)
                .font(.system(size: 14))
                .foregroundStyle(secondaryTextColor)
        }
        .padding(16)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if method == .upi {
                VStack(alignment: .leading, spacing: 12) {
                    Text("CHOOSE YOUR UPI APP")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(secondaryTextColor)
                        .padding(.leading, 4)
                    
                    HStack(spacing: 12) {
                        UPIAppButton(name: "PhonePe", icon: "p.square.fill", color: .purple) {
                            openSpecificUPI(scheme: "phonepe://pay")
                        }
                        UPIAppButton(name: "GPay", icon: "g.circle.fill", color: .blue) {
                            openSpecificUPI(scheme: "tez://upi/pay")
                        }
                        UPIAppButton(name: "Paytm", icon: "pyramid.fill", color: .cyan) {
                            openSpecificUPI(scheme: "paytmmp://pay")
                        }
                        UPIAppButton(name: "Other", icon: "arrow.up.right.circle.fill", color: .gray) {
                            openUPIIntent()
                        }
                    }
                }
                .padding(.bottom, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("After payment, return here and tap Continue.")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.orange)
                }
                .padding(.bottom, 8)
            }

            Button(action: onComplete) {
                Text(method == .upi ? "VERIFY & CONTINUE" : "I'VE PAID / CONTINUE")
                    .font(.system(size: 16, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryColor)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Button("Cancel Order") { dismiss() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(secondaryTextColor)
        }
    }

    private func openSpecificUPI(scheme: String) {
        guard var components = URLComponents(string: scheme) else { return }
        components.queryItems = upiQueryItems()
        guard let url = components.url else { return }
        UIApplication.shared.open(url) { success in
            if !success { openUPIIntent() }
        }
    }

    private func openUPIIntent() {
        guard var components = URLComponents(string: "upi://pay") else { return }
        components.queryItems = upiQueryItems()
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }

    private func upiQueryItems() -> [URLQueryItem] {
        [
            URLQueryItem(name: "pa",  value: merchantUPIID),
            URLQueryItem(name: "pn",  value: "VSN Wholesale"),
            URLQueryItem(name: "am",  value: String(format: "%.2f", orderTotal)),
            URLQueryItem(name: "cu",  value: "INR"),
            URLQueryItem(name: "tn",  value: "VSN Wholesale Order Payment")
        ]
    }

    private func fetchMerchantUPIID() {
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                   let upiID = json["upi_id"], !upiID.isEmpty {
                    await MainActor.run { merchantUPIID = upiID }
                }
            } catch {
                // Keep using the fallback default
                print("Could not fetch merchant UPI ID: \(error)")
            }
        }
    }

    // MARK: - Derived
    private var methodTitle: String {
        switch method {
        case .cod: return "Cash on Delivery"
        case .upi: return "UPI Payment"
        case .bank: return "Bank Transfer"
        default: return method.rawValue
        }
    }
    
    private var methodIcon: String {
        switch method {
        case .cod: return "banknote"
        case .upi: return "qrcode"
        case .bank: return "building.columns"
        default: return "creditcard"
        }
    }
    
    private var methodDetails: String {
        switch method {
        case .cod:
            return "Your order will be processed with Cash on Delivery. Please keep the exact amount ready at delivery."
        case .upi:
            return "Open your UPI app and pay ₹\(Int(orderTotal)) to UPI ID: \(merchantUPIID). After completing the payment, tap Continue."
        case .bank:
            return "Transfer ₹\(Int(orderTotal)) to Account: 1234567890, IFSC: ABCD0123456, Bank: Demo Bank. Add your order ID in remarks if available, then tap Continue."
        default:
            return "Follow the instructions for your selected payment method and tap Continue once done."
        }
    }
    
    // MARK: - Colors with graceful fallbacks
    private var primaryColor: Color {
        #if canImport(SwiftUI)
        return (AppColors.primary as? Color) ?? Color.accentColor
        #else
        return Color.accentColor
        #endif
    }
    private var secondaryTextColor: Color {
        (AppColors.textSecondary as? Color) ?? Color.secondary
    }
    private var surfaceColor: Color {
        (AppColors.surfaceLight as? Color) ?? Color(UIColor.secondarySystemBackground)
    }
    private var backgroundColor: Color {
        (AppColors.background as? Color) ?? Color(UIColor.systemBackground)
    }
}

struct UPIAppButton: View {
    let name: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
	        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Text(name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary as? Color ?? .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.surfaceLight as? Color ?? Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.2), lineWidth: 1))
        }
    }
}

#Preview {
    PaymentInstructionsView(orderTotal: 1999, method: .upi) { }
}
