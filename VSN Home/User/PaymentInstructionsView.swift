import SwiftUI

struct PaymentInstructionsView: View {
    let orderTotal: Double
    let method: PaymentMethod
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
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
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount Due")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(secondaryTextColor)
            Text("₹\(Int(orderTotal)))")
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
        VStack(spacing: 12) {
            Button(action: onComplete) {
                Text("I'VE PAID / CONTINUE")
                    .font(.system(size: 16, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryColor)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button("Cancel") { dismiss() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(secondaryTextColor)
        }
    }
    
    // MARK: - Derived
    private var methodTitle: String {
        switch method {
        case .cod: return "Cash on Delivery"
        case .upi: return "UPI Payment"
        case .bankTransfer: return "Bank Transfer"
        default: return method.rawValue
        }
    }
    
    private var methodIcon: String {
        switch method {
        case .cod: return "banknote"
        case .upi: return "qrcode"
        case .bankTransfer: return "building.columns"
        default: return "creditcard"
        }
    }
    
    private var methodDetails: String {
        switch method {
        case .cod:
            return "Your order will be processed with Cash on Delivery. Please keep the exact amount ready at delivery."
        case .upi:
            return "Open your UPI app and pay ₹\(Int(orderTotal)) to our UPI ID: grocery@upi. After completing the payment, tap Continue."
        case .bankTransfer:
            return "Transfer ₹\(Int(orderTotal)) to Account: 1234567890, IFSC: ABCD0123456, Bank: Demo Bank. Add your order ID in remarks if available, then tap Continue."
        default:
            return "Follow the instructions for your selected payment method and tap Continue once done."
        }
    }
    
    // MARK: - Colors with graceful fallbacks
    private var primaryColor: Color {
        // Use AppColors.primary if available, else fallback
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

#Preview {
    PaymentInstructionsView(orderTotal: 1999, method: .upi) { }
}
