import SwiftUI

// MARK: - Admin Order Detail (Modern B2B Order Management)
struct AdminOrderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var productStore: GroceryProductStore
    @State var order: Order
    @State private var useCustomDate: Bool = false
    @State private var selectedDate: Date = Date()
    @State private var isSaving = false

    private let allOrderStatuses: [OrderStatus] = [.pending, .processing, .outForDelivery, .delivered, .cancelled]
    private let allPaymentStatuses: [PaymentStatus] = [.pending, .paid, .failed, .refunded]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Order #\(order.id.prefix(8).uppercased())")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Manage lifecycle and logistics for this business order.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    
                    // 1. Status Management
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Management Control")
                            .font(.system(size: 16, weight: .bold))
                        
                        VStack(spacing: 16) {
                            StatusPickerField(label: "Order Status", selection: $order.status, options: allOrderStatuses)
                            StatusPickerField(label: "Payment Status", selection: $order.paymentStatus, options: allPaymentStatuses)
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // 2. Schedule
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Delivery Schedule")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Toggle("", isOn: $useCustomDate)
                                .labelsHidden()
                        }
                        
                        if useCustomDate {
                            DatePicker("Custom Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .font(.system(size: 14, weight: .medium))
                                .onChange(of: selectedDate) { order.customDeliveryDate = $0 }
                        } else {
                            Text("Defaults to automated logistical calculation.")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // 3. Item Manifest
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("ITEM MANIFEST")
                                .font(.system(size: 14, weight: .black))
                                .tracking(1)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(order.items.count) Items")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(order.items) { item in
                                HStack(spacing: 16) {
                                    ProductImageView(imageName: item.product.image)
                                        .frame(width: 40, height: 40)
                                        .cornerRadius(6)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.product.name)
                                            .font(.system(size: 14, weight: .bold))
                                        Text("SKU: \(item.product.id.prefix(6).uppercased())")
                                            .font(.system(size: 10))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("₹\(Int(item.product.wholesalePrice)) × \(item.quantity)")
                                            .font(.system(size: 12))
                                        Text("₹\(Int(item.product.wholesalePrice * Double(item.quantity)))")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                                .padding(.vertical, 12)
                                
                                if item.id != order.items.last?.id {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        
                        VStack(spacing: 12) {
                            Divider()
                            SummaryLineView(label: "Subtotal", value: "₹\(Int(order.total + order.discountAmount - order.deliveryCharge))")
                            if order.discountAmount > 0 {
                                SummaryLineView(label: "Applied Discount", value: "-₹\(Int(order.discountAmount))", color: AppColors.success)
                            }
                            if order.deliveryCharge > 0 {
                                SummaryLineView(label: "Logistics Charge", value: "+₹\(Int(order.deliveryCharge))")
                            }
                            HStack {
                                Text("Final Receivable")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Text("₹\(Int(order.total))")
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // 4. Customer & Shipping
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Logistics Identity")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill").foregroundColor(AppColors.primary).frame(width: 20)
                                Text(order.userEmail).font(.system(size: 14, weight: .medium))
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.red).frame(width: 20)
                                Text(order.address).font(.system(size: 13)).lineLimit(3)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("SAVE CHANGES")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                        }
                        .disabled(isSaving)
                        
                        Button(action: downloadBill) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                Text("DOWNLOAD SALES BILL")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(AppColors.primary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.primary.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .hidesTabBar()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .onAppear {
            if let customDate = order.customDeliveryDate {
                useCustomDate = true
                selectedDate = customDate
            }
        }
    }
    
    private func downloadBill() {
        HapticManager.shared.trigger(.medium)
        // Generate PDF using shared InvoiceGenerator
        if let url = InvoiceGenerator.generateInvoicePDF(order: order, selectedLanguage: .english) {
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            // For iPad compatibility
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                av.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(av, animated: true)
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            await productStore.updateOrderStatus(order)
            await MainActor.run { isSaving = false; dismiss() }
        }
    }
}

struct StatusPickerField<T: RawRepresentable>: View where T.RawValue == String, T: Hashable {
    let label: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        }
    }
}
