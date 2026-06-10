import SwiftUI

// MARK: - Order Tracking View (Refined B2B Tracking)
struct OrderTrackingView: View {
    let order: Order
    let selectedLanguage: AppLanguage
    
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGenerating = false
    
    var steps: [String] {
        ["Order Placed", "Processing", "Out for Delivery", "Delivered"]
    }
    
    var currentStepIndex: Int {
        switch order.status {
        case .pending: return 0
        case .processing: return 1
        case .outForDelivery: return 2
        case .delivered: return 3
        case .cancelled: return -1
        }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    timelineSection
                    summarySection
                    actionSection
                }
                .padding(.vertical, 24)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ActivityView(activityItems: [url])
            }
        }
        .navigationTitle("Track Order")
        .hidesTabBar()
    }
    
    // MARK: - Sub-Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORDER ID")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    Text("#\(order.id.prefix(12).uppercased())")
                        .font(.system(size: 18, weight: .black))
                }
                Spacer()
                Text(order.paymentStatus.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(paymentStatusColor(order.paymentStatus).opacity(0.1))
                    .foregroundColor(paymentStatusColor(order.paymentStatus))
                    .cornerRadius(6)
            }
            
            Divider()
            
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppColors.primary)
                VStack(alignment: .leading) {
                    Text("Estimated Arrival")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                    Text(order.deliveryDateString)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
        .padding(.horizontal, 22)
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Delivery Status")
                .font(.system(size: 16, weight: .bold))
                .padding(.horizontal, 2)
            
            if order.status == .cancelled {
                HStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("This order was cancelled.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        DeliveryStepRow(
                            title: steps[index],
                            isCompleted: index <= currentStepIndex,
                            isCurrent: index == currentStepIndex,
                            isLast: index == steps.count - 1
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(20)
        .padding(.horizontal, 22)
    }
    
    private var summarySection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Order Summary")
                    .font(.system(size: 16, weight: .bold))
                
                VStack(spacing: 12) {
                    let items = consolidate(order.items ?? [])
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.product.localizedName(for: selectedLanguage))
                                    .font(.system(size: 14, weight: .bold))
                                Text("Qty: \(item.quantity)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text("₹\(Int(item.product.wholesalePrice * Double(item.quantity)))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
                
                Divider()
                
                VStack(spacing: 10) {
                    if let offer = order.appliedOfferTitle {
                        SummaryItemLine(label: "Offer: \(offer)", value: "-₹\(Int(order.discountAmount))", color: AppColors.success)
                    }
                    SummaryItemLine(label: "Grand Total", value: "₹\(Int(order.total))", isBold: true)
                }
            }
            .padding(20)
            .background(AppColors.surfaceLight)
            .cornerRadius(20)
            
            if order.requiresGSTBill ?? false {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GST Billing Details")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    Text(order.businessName ?? "N/A")
                        .font(.system(size: 14, weight: .bold))
                    Text("GSTIN: \(order.gstNumber ?? "N/A")")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.primary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surfaceLight)
                .cornerRadius(16)
            }
            
            // Download Bill Button
            Button(action: {
                HapticManager.shared.trigger(.medium)
                isGenerating = true
                Task {
                    let url = InvoiceGenerator.generateInvoicePDF(order: order, selectedLanguage: selectedLanguage)
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                        if url != nil {
                            self.showShareSheet = true
                        }
                    }
                }
            }) {
                HStack(spacing: 12) {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                    }
                    Text(isGenerating ? "GENERATING..." : "DOWNLOAD TAX INVOICE")
                        .font(.system(size: 13, weight: .black))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.primary)
                .cornerRadius(16)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 8)
            
            // Support Shortcut
            Button(action: {
                let text = "Support needed for Order #\(order.id.prefix(8).uppercased())"
                let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "https://wa.me/919059270899?text=\(encodedText)") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("CONTACT SUPPORT FOR THIS ORDER")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                }
                .foregroundColor(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(14)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 22)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            if order.status == .outForDelivery {
                Button(action: { /* Haptic & Call action */ }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Contact Delivery Agent")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }
            
            Button(action: {
                HapticManager.shared.trigger(.medium)
                isGenerating = true
                Task {
                    let url = InvoiceGenerator.generateInvoicePDF(order: order, selectedLanguage: selectedLanguage)
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                        if url != nil {
                            self.showShareSheet = true
                        }
                    }
                }
            }) {
                HStack {
                    if isGenerating {
                        ProgressView().tint(.blue)
                    } else {
                        Image(systemName: "doc.text.fill")
                    }
                    Text(isGenerating ? "Generating PDF..." : "Download PDF Invoice")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 22)
    }
    
    private func consolidate(_ items: [GroceryCartItem]) -> [GroceryCartItem] {
        var dict: [String: GroceryCartItem] = [:]
        for item in items {
            if let existing = dict[item.product.name] {
                var newItem = existing
                newItem.quantity += item.quantity
                dict[item.product.name] = newItem
            } else { dict[item.product.name] = item }
        }
        return Array(dict.values).sorted { $0.product.name < $1.product.name }
    }
    
    private func paymentStatusColor(_ status: PaymentStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .paid: return AppColors.success
        case .failed: return .red
        case .refunded: return .gray
        }
    }
}

struct DeliveryStepRow: View {
    let title: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? AppColors.primary : Color.gray.opacity(0.2))
                        .frame(width: 24, height: 24)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? AppColors.primary : Color.gray.opacity(0.2))
                        .frame(width: 2, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: isCurrent ? .bold : .medium))
                    .foregroundColor(isCompleted ? AppColors.textPrimary : AppColors.textSecondary)
                if isCurrent {
                    Text("In Progress")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.top, 2)
            
            Spacer()
        }
    }
}

struct SummaryItemLine: View {
    let label: String
    let value: String
    var color: Color = AppColors.textPrimary
    var isBold: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: isBold ? .bold : .regular))
                .foregroundColor(isBold ? AppColors.textPrimary : AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: isBold ? .black : .bold))
                .foregroundColor(color)
        }
    }
}
