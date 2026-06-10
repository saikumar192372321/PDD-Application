import SwiftUI

// MARK: - Admin Add Offer View
struct AddOfferView: View {
    @ObservedObject var productStore: GroceryProductStore
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var minOrderValue = ""
    @State private var discountType: DiscountType = .percentage
    @State private var discountValue = ""
    
    enum DiscountType: String, CaseIterable {
        case percentage = "Percentage (%)"
        case flat = "Flat Amount (₹)"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header Panel
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "tag.circle.fill")
                            .foregroundColor(AppColors.secondary)
                        Text("OFFER CONFIGURATION")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text("New Discount Protocol")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Input Matrix
                VStack(spacing: 24) {
                    SectionHeader(title: "Nomenclature")
                    VanguardInput(label: "OFFER TITLE", text: $title, placeholder: "e.g. Bulk Savings - 10%", icon: "tag.fill")
                    VanguardInput(label: "FIELD DESCRIPTION", text: $description, placeholder: "Get a discount on orders above ₹...", icon: "text.alignleft")
                    
                    SectionHeader(title: "Compliance Conditions")
                    VanguardInput(label: "MINIMUM ORDER THRESHOLD (₹)", text: $minOrderValue, placeholder: "e.g. 1000", icon: "cart.fill.badge.plus", keyboard: .numberPad)
                    
                    SectionHeader(title: "Yield Calculation")
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Label("DISCOUNT TYPE", systemImage: "percent")
                            .font(.system(size: 8, weight: .black))
                            .tracking(1)
                            .foregroundColor(AppColors.secondary)
                        
                        Picker("", selection: $discountType) {
                            ForEach(DiscountType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(8)
                        .background(AppColors.background)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                    }

                    VanguardInput(
                        label: discountType == .percentage ? "PERCENTAGE YIELD (%)" : "FLAT REBATE (₹)",
                        text: $discountValue,
                        placeholder: discountType == .percentage ? "e.g. 10" : "e.g. 100",
                        icon: "bolt.fill",
                        keyboard: .decimalPad
                    )
                }
                .padding(32)
                .background(AppColors.background)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                .shadow(color: AppColors.primary.opacity(0.1), radius: 0, x: 4, y: 4)
                .padding(.horizontal, 24)

                // Activation Button
                Button(action: saveOffer) {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                        Text("ACTIVATE OFFER SEQUENCE")
                            .font(.system(size: 14, weight: .black))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(title.isEmpty || minOrderValue.isEmpty || discountValue.isEmpty ? AnyShapeStyle(AppColors.textPrimary.opacity(0.05)) : AnyShapeStyle(AppColors.primaryGradient))
                    .foregroundColor(title.isEmpty || minOrderValue.isEmpty || discountValue.isEmpty ? AppColors.textSecondary.opacity(0.2) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: (title.isEmpty || minOrderValue.isEmpty || discountValue.isEmpty) ? .clear : AppColors.primary.opacity(0.2), radius: 0, x: 2, y: 2)
                }
                .disabled(title.isEmpty || minOrderValue.isEmpty || discountValue.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .atmosphericBackground()
        .hidesTabBar()
    }
    
    func saveOffer() {
        guard let minVal = Double(minOrderValue),
              let dValue = Double(discountValue) else { return }
        
        let newOffer = BulkOffer(
            title: title,
            description: description,
            minOrderValue: minVal,
            discountPercentage: discountType == .percentage ? (dValue / 100.0) : nil,
            discountAmount: discountType == .flat ? dValue : nil
        )
        
        Task {
            await productStore.addOffer(newOffer)
        }
        HapticManager.shared.notify(.success)
        dismiss()
    }
}
