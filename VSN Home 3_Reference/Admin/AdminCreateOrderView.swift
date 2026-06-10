import SwiftUI

struct AdminCreateOrderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var productStore: GroceryProductStore
    
    @State private var userEmail = ""
    @State private var shippingAddress = ""
    @State private var selectedItems: [GroceryCartItem] = []
    @State private var selectedOffer: BulkOffer?
    @State private var isPlacingOrder = false
    @State private var showProductPicker = false
    
    var subtotal: Double {
        selectedItems.reduce(0) { $0 + ($1.product.wholesalePrice * Double($1.quantity)) }
    }
    
    var discount: Double {
        guard let offer = selectedOffer else { return 0 }
        if let amount = offer.discountAmount { return amount }
        if let pct = offer.discountPercentage { return subtotal * pct }
        return 0
    }
    
    var total: Double { max(0, subtotal - discount) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        customerInfoSection
                        itemsSection
                        offerSection
                        summarySection
                        placeOrderButton
                    }
                    .padding(22)
                }
            }
            .navigationTitle("Manual Order Entry")
            .navigationBarTitleDisplayMode(.inline)
            .hidesTabBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showProductPicker) {
                AdminProductPicker(products: productStore.products) { product in
                    if let index = selectedItems.firstIndex(where: { $0.product.id == product.id }) {
                        selectedItems[index].quantity += 1
                    } else {
                        selectedItems.append(GroceryCartItem(product: product, quantity: product.minOrderQty ?? 1))
                    }
                }
            }
        }
    }
    
    var isValid: Bool {
        !userEmail.isEmpty && userEmail.contains("@") && !selectedItems.isEmpty && !shippingAddress.isEmpty
    }
    
    private func updateQty(for item: GroceryCartItem, by amount: Int) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            let newQty = selectedItems[index].quantity + amount
            if newQty >= (item.product.minOrderQty ?? 1) {
                selectedItems[index].quantity = newQty
            }
        }
    }
    
    private func placeManualOrder() {
        isPlacingOrder = true
        
        let newOrder = Order(
            id: UUID().uuidString,
            date: Date(),
            items: selectedItems,
            total: total,
            status: .pending,
            paymentStatus: .pending,
            paymentMethod: .cod,
            address: shippingAddress,
            userEmail: userEmail,
            customDeliveryDate: nil,
            requiresGSTBill: false,
            discountAmount: discount,
            appliedOfferTitle: selectedOffer?.title,
            coinsEarned: 0
        )
        
        Task {
            guard let url = URL(string: APIConfig.baseURL + "place_order.php") else { return }
            
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                request.httpBody = try JSONEncoder().encode(newOrder)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
                
                await MainActor.run {
                    isPlacingOrder = false
                    if response.status == "success" {
                        productStore.orders.insert(newOrder, at: 0)
                        HapticManager.shared.notify(.success)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run { isPlacingOrder = false }
                print("Failed to place manual order: \(error)")
            }
        }
    }
}

// MARK: - Subviews
private extension AdminCreateOrderView {
    var customerInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customer Information")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            
            VanguardInput(label: "CUSTOMER EMAIL", text: $userEmail, icon: "envelope.fill")
            VanguardInput(label: "SHIPPING ADDRESS", text: $shippingAddress, icon: "mappin.and.ellipse")
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
    }
    
    var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Order Items")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Button(action: { showProductPicker = true }) {
                    Label("Add Item", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            
            if selectedItems.isEmpty {
                Text("No items added yet.")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 10)
            } else {
                ForEach(selectedItems) { item in
                    HStack {
                        Text(item.product.name)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { updateQty(for: item, by: -1) }) {
                                Image(systemName: "minus.square")
                            }
                            Text("\(item.quantity)")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 30)
                            Button(action: { updateQty(for: item, by: 1) }) {
                                Image(systemName: "plus.square")
                            }
                            
                            Button(action: { selectedItems.removeAll(where: { $0.id == item.id }) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
    }
    
    var offerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apply Business Offer")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(productStore.bulkOffers) { offer in
                        OfferChip(offer: offer, currentTotal: subtotal, isSelected: selectedOffer?.id == offer.id) {
                            selectedOffer = (selectedOffer?.id == offer.id) ? nil : offer
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
    }
    
    var summarySection: some View {
        VStack(spacing: 12) {
            SummaryLineView(label: "Subtotal", value: "₹\(Int(subtotal))")
            if discount > 0 {
                SummaryLineView(label: "Admin Discount", value: "-₹\(Int(discount))", color: AppColors.success)
            }
            Divider()
            HStack {
                Text("Total Amount")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("₹\(Int(total))")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
    }
    
    var placeOrderButton: some View {
        Button(action: placeManualOrder) {
            if isPlacingOrder {
                ProgressView().tint(.white)
            } else {
                Text("INITIALIZE MANUAL ORDER")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isValid ? AppColors.primary : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .disabled(!isValid || isPlacingOrder)
        .padding(.bottom, 40)
    }
}

struct AdminProductPicker: View {
    let products: [GroceryProduct]
    let onSelect: (GroceryProduct) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(products) { product in
                Button(action: { onSelect(product); dismiss() }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name).font(.headline)
                            Text("Wholesale: ₹\(Int(product.wholesalePrice))").font(.caption)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .navigationTitle("Select Product")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
