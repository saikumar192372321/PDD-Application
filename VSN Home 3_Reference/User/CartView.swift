import SwiftUI
import CoreLocation

// MARK: - Cart View (Refined B2B Flow)
struct CartView: View {
    @ObservedObject var productStore: GroceryProductStore
    @Binding var cartItems: [GroceryCartItem]
    @Binding var userCoins: Int
    @Binding var orders: [Order]
    @Binding var selectedTab: GroceryAppView.Tab
    @Binding var userAddress: String
    @Binding var userLatitude: Double
    @Binding var userLongitude: Double
    @Binding var selectedOffer: BulkOffer?
    let selectedLanguage: AppLanguage
    let userEmail: String
    @EnvironmentObject var tabBarState: TabBarState
    
    @State private var showCheckoutSuccess = false
    @State private var showAddressSheet = false
    @State private var shopName = ""
    @State private var shopNumber = ""
    @State private var street = ""
    @State private var landmark = ""
    @State private var pincode = ""
    @State private var city = ""
    @State private var latitude: Double = 0
    @State private var longitude: Double = 0
    @State private var requiresGST = false
    @State private var businessGSTName = ""
    @State private var gstNumber = ""
    @State private var isLoading = false
    @State private var selectedPaymentMethod: PaymentMethod = .cod
    @State private var showPaymentInstructions = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showRazorpayDummy = false
    
    // Logistics settings from server
    @State private var hubLatitude: Double = 21.1458
    @State private var hubLongitude: Double = 79.0882
    @State private var allowedRadius: Double = 25.0 // km
    @State private var currentDistance: Double = 0.0
    @State private var deliveryCharge: Double = 0.0
    @State private var freeThreshold: Double = 5000.0
    @State private var deliveryNote: String = ""
    @State private var isFetchingLogistics = true
    
    let minOrderValue: Double = 1000 // Wholesale minimum
    
    var totalPrice: Double {
        cartItems.reduce(0) { $0 + ($1.product.wholesalePrice * Double($1.quantity)) }
    }
    
    var discountAmount: Double {
        guard let offer = selectedOffer else { return 0 }
        if let amount = offer.discountAmount {
            return amount
        } else if let percentage = offer.discountPercentage {
            return totalPrice * (percentage / 100)
        }
        return 0
    }
    
    var isFreeDelivery: Bool {
        totalPrice >= freeThreshold
    }
    
    var finalPrice: Double {
        let charge = isFreeDelivery ? 0 : deliveryCharge
        return max(0, totalPrice - discountAmount + charge)
    }
    
    var totalSavings: Double {
        let baseSavings = cartItems.reduce(0) { $0 + ($1.product.savings * Double($1.quantity)) }
        return baseSavings + discountAmount
    }
    
    var earnedCoins: Int {
        cartItems.reduce(0) { total, item in
            if let offer = item.product.coinOffer, item.quantity >= offer.thresholdQuantity {
                return total + offer.rewardCoins
            }
            return total
        }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                if cartItems.isEmpty {
                    EmptyCartPlaceholder(selectedTab: $selectedTab)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            
                            // 1. Logistics Threshold (Progress Info)
                            VStack(spacing: 12) {
                                ThresholdProgressView(totalPrice: totalPrice, minOrderValue: minOrderValue)
                                
                                if !userAddress.isEmpty && !isFetchingLogistics {
                                    HStack {
                                        Image(systemName: currentDistance > allowedRadius ? "mappin.slash.circle.fill" : "truck.box.fill")
                                            .foregroundColor(currentDistance > allowedRadius ? .red : AppColors.success)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(currentDistance > allowedRadius ? "Outside Delivery Zone" : "Within Delivery Zone")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(currentDistance > allowedRadius ? .red : AppColors.textPrimary)
                                            
                                            Text("Your shop is \(String(format: "%.1f", currentDistance))km away (Limit: \(Int(allowedRadius))km)")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(currentDistance > allowedRadius ? Color.red.opacity(0.1) : AppColors.success.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 2. Cart Items
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Order Inventory")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Button(action: {
                                        withAnimation { cartItems.removeAll() }
                                    }) {
                                        Text("Clear All")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.red.opacity(0.08))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 22)
                                
                                ForEach($cartItems) { $item in
                                    CompactCartItemCard(item: $item, selectedLanguage: selectedLanguage) {
                                        withAnimation {
                                            cartItems.removeAll(where: { $0.id == item.id })
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                cartItems.removeAll(where: { $0.id == item.id })
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            
                            // 3. Shipping Target
                            ShippingTargetCard(userAddress: userAddress) {
                                if !userAddress.isEmpty { parseAddress() }
                                latitude = userLatitude
                                longitude = userLongitude
                                showAddressSheet = true
                            }
                            .padding(.horizontal, 20)
                            
                            // 4. Available Offers
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Business Offers")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.horizontal, 22)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(productStore.bulkOffers) { offer in
                                            OfferChip(offer: offer, currentTotal: totalPrice, isSelected: selectedOffer?.id == offer.id) {
                                                selectedOffer = (selectedOffer?.id == offer.id) ? nil : offer
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 22)
                                }
                            }
                            
                            // 5. Financial Config (GST & Payment)
                            FinanceSection(
                                selectedPaymentMethod: $selectedPaymentMethod,
                                requiresGST: $requiresGST,
                                businessGSTName: $businessGSTName,
                                gstNumber: $gstNumber
                            )
                            .padding(.horizontal, 20)
                            
                            // 6. Final Summary
                            SummaryCard(totalPrice: totalPrice, discountAmount: discountAmount, deliveryCharge: deliveryCharge, deliveryNote: deliveryNote, freeThreshold: freeThreshold, finalPrice: finalPrice, totalSavings: totalSavings, earnedCoins: earnedCoins, selectedOffer: selectedOffer, cartItems: cartItems)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 120) // Space for footer
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle("Your Logistics Hub")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !cartItems.isEmpty {
                CheckoutFooter(
                    finalPrice: finalPrice,
                    minOrderValue: minOrderValue,
                    requiresGST: requiresGST,
                    businessGSTName: businessGSTName,
                    gstNumber: gstNumber,
                    selectedPaymentMethod: selectedPaymentMethod,
                    allowedRadius: allowedRadius,
                    currentDistance: currentDistance,
                    isLoading: isLoading,
                    onCheckout: {
                        if selectedPaymentMethod == .cod { placeOrder() }
                        else if selectedPaymentMethod == .razorpay || selectedPaymentMethod == .razorpayDummy { 
                            showRazorpayDummy = true 
                        } else { 
                            showPaymentInstructions = true 
                        }
                    }
                )
                .padding(.bottom, tabBarState.isHidden ? 20 : 100)
            }
        }
        .fullScreenCover(isPresented: $showPaymentInstructions) {
            PaymentInstructionsView(
                orderTotal: finalPrice,
                method: selectedPaymentMethod,
                onComplete: {
                    placeOrder()
                    showPaymentInstructions = false
                }
            )
            .environmentObject(tabBarState)
        }
        .fullScreenCover(isPresented: $showRazorpayDummy) {
            RazorpayCheckoutView(amount: finalPrice, userEmail: userEmail) { success in
                if success { placeOrder() }
            }
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressConfigView(
                shopName: $shopName,
                shopNumber: $shopNumber,
                street: $street,
                landmark: $landmark,
                city: $city,
                pincode: $pincode,
                latitude: $latitude,
                longitude: $longitude,
                onSave: {
                    saveAddress()
                    userLatitude = latitude
                    userLongitude = longitude
                    showAddressSheet = false
                }
            )
        }
        .alert("Order Successful", isPresented: $showCheckoutSuccess) {
            Button("View Orders") { selectedTab = .profile }
        } message: {
            Text("Order of ₹\(Int(finalPrice)) has been placed.\nConfirmation sent to \(userEmail).")
        }
        .alert("Order Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear { 
            consolidateCartItems()
            fetchLogisticsSettings()
        }
    }
    
    private func consolidateCartItems() {
        var dict: [String: GroceryCartItem] = [:]
        for item in cartItems {
            if let existing = dict[item.product.name] {
                var newItem = existing
                newItem.quantity += item.quantity
                dict[item.product.name] = newItem
            } else { dict[item.product.name] = item }
        }
        let merged = Array(dict.values).sorted { $0.product.name < $1.product.name }
        if merged.count != cartItems.count {
            cartItems = merged
        }
    }
    
    private func saveAddress() {
        var parts: [String] = []
        if !shopName.isEmpty { parts.append(shopName) }
        if !shopNumber.isEmpty { parts.append(shopNumber) }
        if !street.isEmpty { parts.append(street) }
        if !landmark.isEmpty { parts.append("Near \(landmark)") }
        if !city.isEmpty { parts.append(city) }
        if !pincode.isEmpty { parts.append(pincode) }
        userAddress = parts.joined(separator: ", ")
        updateDistance()
    }
    
    private func parseAddress() {
        let parts = userAddress.components(separatedBy: ", ")
        if parts.count >= 4 {
            shopName = parts[0]
            shopNumber = parts[1]
            street = parts[2]
            city = parts.last(where: { !$0.isEmpty && $0.rangeOfCharacter(from: .decimalDigits) == nil }) ?? ""
            pincode = parts.last(where: { $0.count == 6 && $0.rangeOfCharacter(from: .decimalDigits) != nil }) ?? ""
        }
    }
    
    private func fetchLogisticsSettings() {
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    await MainActor.run {
                        self.allowedRadius = Double(json["delivery_radius"] ?? "25") ?? 25.0
                        self.hubLatitude = Double(json["hub_latitude"] ?? "21.1458") ?? 21.1458
                        self.hubLongitude = Double(json["hub_longitude"] ?? "79.0882") ?? 79.0882
                        self.deliveryCharge = Double(json["delivery_charge"] ?? "0") ?? 0.0
                        self.freeThreshold = Double(json["free_delivery_threshold"] ?? "5000") ?? 5000.0
                        self.deliveryNote = json["delivery_note"] ?? ""
                        self.isFetchingLogistics = false
                        updateDistance()
                    }
                }
            } catch {
                await MainActor.run { self.isFetchingLogistics = false }
            }
        }
    }
    
    private func updateDistance() {
        guard userLatitude != 0 && userLongitude != 0 else {
            currentDistance = 0
            return
        }
        let userLoc = CLLocation(latitude: userLatitude, longitude: userLongitude)
        let hubLoc = CLLocation(latitude: hubLatitude, longitude: hubLongitude)
        currentDistance = userLoc.distance(from: hubLoc) / 1000.0 // To KM
    }
    
    private func placeOrder() {
        if isLoading { return }
        
        if userAddress.isEmpty {
            showAddressSheet = true
            return
        }
        
        let newOrder = Order(
            id: UUID().uuidString,
            date: Date(),
            items: cartItems,
            total: finalPrice,
            status: .pending,
            paymentStatus: .pending,
            paymentMethod: selectedPaymentMethod,
            address: userAddress,
            userEmail: userEmail,
            customDeliveryDate: nil,
            requiresGSTBill: requiresGST,
            businessName: requiresGST ? businessGSTName : nil,
            gstNumber: requiresGST ? gstNumber : nil,
            discountAmount: discountAmount,
            deliveryCharge: deliveryCharge,
            appliedOfferTitle: selectedOffer?.title,
            coinsEarned: earnedCoins
        )
        
        isLoading = true
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL + "place_order.php") else {
            errorMessage = "Invalid server configuration."
            showErrorAlert = true
            isLoading = false
            return
        }
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(newOrder)
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                // Debug: print(String(data: data, encoding: .utf8) ?? "No data")
                
                let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
                
                await MainActor.run {
                    isLoading = false
                    if response.status == "success" {
                        orders.insert(newOrder, at: 0)
                        productStore.saveLocalOrders(for: userEmail) // ✅ Persist immediately
                        cartItems.removeAll()
                        selectedOffer = nil
                        userCoins += earnedCoins
                        showCheckoutSuccess = true
                        HapticManager.shared.notify(.success)
                    } else {
                        errorMessage = response.message
                        showErrorAlert = true
                        HapticManager.shared.notify(.error)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Network error: Please check your connection and try again."
                    showErrorAlert = true
                    HapticManager.shared.notify(.error)
                }
            }
        }
    }
}

// MARK: - Subcomponents

struct EmptyCartPlaceholder: View {
    @Binding var selectedTab: GroceryAppView.Tab
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primary.opacity(0.3))
            
            Text("No Stock in Selection")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text("You haven't added any products to your wholesale choice. Minimum order value is ₹1,000.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { selectedTab = .home }) {
                Text("BROWSE CATALOG")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

struct ThresholdProgressView: View {
    let totalPrice: Double
    let minOrderValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wholesale Tier Status")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(totalPrice >= minOrderValue ? "QUALIFIED" : "₹\(Int(totalPrice)) / ₹\(Int(minOrderValue))")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(totalPrice >= minOrderValue ? AppColors.success : .orange)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.05))
                    Capsule()
                        .fill(totalPrice >= minOrderValue ? AppColors.success : .orange)
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(totalPrice / minOrderValue)))
                }
            }
            .frame(height: 8)
            
            if totalPrice < minOrderValue {
                Text("Add ₹\(Int(minOrderValue - totalPrice)) more to unlock wholesale pricing and logistics.")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(16)
        .background(AppColors.surfaceLight)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct CompactCartItemCard: View {
    @Binding var item: GroceryCartItem
    let selectedLanguage: AppLanguage
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ProductImageView(imageName: item.product.image)
                .frame(width: 70, height: 70)
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.localizedName(for: selectedLanguage))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text(item.product.details?.brand! ?? "")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(spacing: 8) {
                    Text("₹\(Int(item.product.wholesalePrice))")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(AppColors.primary)
                    
                    Text("x \(item.quantity)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                
                HStack(spacing: 12) {
                    Button(action: { if item.quantity > (item.product.minOrderQty ?? 1) { item.quantity -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .disabled(item.quantity <= (item.product.minOrderQty ?? 1))
                    .foregroundColor(item.quantity <= (item.product.minOrderQty ?? 1) ? Color(UIColor.systemGray4) : AppColors.primary)
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 16, weight: .bold))
                        .frame(minWidth: 24)
                    
                    Button(action: { item.quantity += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.8))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

struct ShippingTargetCard: View {
    let userAddress: String
    let onEdit: () -> Void
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: 16) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(AppColors.primaryGradient)
                    .clipShape(Circle())
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHIPPING HUB DESTINATION")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(AppColors.textSecondary)
                        .tracking(1)
                    Text(userAddress.isEmpty ? "Tap to add your shop address" : userAddress)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.primary.opacity(0.5))
            }
            .padding(16)
            .background(Color.white.opacity(0.7))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
    }
}

struct OfferChip: View {
    let offer: BulkOffer
    let currentTotal: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.seal.fill" : "seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.success : (currentTotal >= offer.minOrderValue ? AppColors.primary : .gray))
                    Spacer()
                    if currentTotal >= offer.minOrderValue {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(AppColors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppColors.success.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.title)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                    Text(offer.description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(width: 170)
            .background(isSelected ? AppColors.success.opacity(0.08) : Color.white.opacity(0.7))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? AppColors.success : Color.white.opacity(0.5), lineWidth: 1.5)
            )
        }
        .disabled(currentTotal < offer.minOrderValue)
        .opacity(currentTotal < offer.minOrderValue ? 0.6 : 1)
        .shadow(color: isSelected ? AppColors.success.opacity(0.1) : Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct FinanceSection: View {
    @Binding var selectedPaymentMethod: PaymentMethod
    @Binding var requiresGST: Bool
    @Binding var businessGSTName: String
    @Binding var gstNumber: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Payment Selector
            VStack(alignment: .leading, spacing: 12) {
                Label("PREFERENCE", systemImage: "creditcard.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(AppColors.primary)
                    Text("Payment Method")
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    Picker("", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .tint(AppColors.primary)
                }
                .padding(16)
                .background(Color.white.opacity(0.7))
                .cornerRadius(16)
            }
            
            // GST Toggle Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("B2B GST Billing")
                            .font(.system(size: 15, weight: .bold))
                        Text("For registered wholesale partners")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $requiresGST)
                        .tint(AppColors.primary)
                        .labelsHidden()
                }
                .padding(16)
                .background(Color.white.opacity(0.7))
                .cornerRadius(16)
                
                if requiresGST {
                    VStack(spacing: 12) {
                        TextField("Business Legal Name", text: $businessGSTName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(14)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                        
                        TextField("GSTIN Number (15 Digits)", text: $gstNumber)
                            .font(.system(size: 14, weight: .medium))
                            .padding(14)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .padding(12)
                    .background(AppColors.primary.opacity(0.05))
                    .cornerRadius(18)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

struct SummaryCard: View {
    let totalPrice: Double
    let discountAmount: Double
    let deliveryCharge: Double
    let deliveryNote: String
    let freeThreshold: Double
    let finalPrice: Double
    let totalSavings: Double
    let earnedCoins: Int
    let selectedOffer: BulkOffer?
    let cartItems: [GroceryCartItem]
    
    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 12) {
                SummaryLineView(label: "Order Subtotal", value: "₹\(Int(totalPrice))")
                if discountAmount > 0 {
                    SummaryLineView(label: "Offer Discount", value: "-₹\(Int(discountAmount))", color: AppColors.success)
                }
                let isFree = totalPrice >= freeThreshold
                SummaryLineView(label: "Logistics Fee", value: isFree ? "FREE" : "₹\(Int(deliveryCharge))", color: isFree ? AppColors.success : AppColors.textPrimary)
                
                if !isFree && deliveryCharge > 0 {
                    HStack {
                        Spacer()
                        Text("Add ₹\(Int(freeThreshold - totalPrice)) more for FREE delivery")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                if !deliveryNote.isEmpty {
                    Text(deliveryNote)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            Divider().background(Color.black.opacity(0.05))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payable Amount")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                    Text("₹\(Int(finalPrice))")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(AppColors.primary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    if totalSavings > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Saved ₹\(Int(totalSavings))")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppColors.success)
                        .cornerRadius(8)
                    }
                    
                    if earnedCoins > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "pentagon.fill")
                            Text("\(earnedCoins) Coins")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Rewards Tracker
            let potentialIncentives = cartItems.compactMap { item -> (String, Int, Int)? in
                if let offer = item.product.coinOffer, item.quantity < offer.thresholdQuantity {
                    return (item.product.name, offer.thresholdQuantity - item.quantity, offer.rewardCoins)
                }
                return nil
            }
            
            if !potentialIncentives.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text("SMART REWARDS TRACKER")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(AppColors.textSecondary)
                            .tracking(1)
                    }
                    
                    ForEach(potentialIncentives, id: \.0) { name, gap, reward in
                        HStack {
                            Text("Add \(gap) more \(name) to unlock \(reward) coins")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundColor(AppColors.primary.opacity(0.5))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(10)
                    }
                }
                .padding(12)
                .background(AppColors.primary.opacity(0.04))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.7))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 10)
    }
}


struct SummaryLineView: View {
    let label: String
    let value: String
    var color: Color = AppColors.textPrimary
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(color)
        }
    }
}

struct CheckoutFooter: View {
    let finalPrice: Double
    let minOrderValue: Double
    let requiresGST: Bool
    let businessGSTName: String
    let gstNumber: String
    let selectedPaymentMethod: PaymentMethod
    let allowedRadius: Double
    let currentDistance: Double
    let isLoading: Bool
    let onCheckout: () -> Void
    
    var isEligible: Bool {
        let priceOK = finalPrice >= minOrderValue
        let gstOK = !requiresGST || (!businessGSTName.isEmpty && gstNumber.count == 15)
        let distanceOK = currentDistance <= allowedRadius
        return priceOK && gstOK && distanceOK && !isLoading
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Shadow Gradient Overlay for transparency effect
            LinearGradient(colors: [.clear, Color.black.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                .frame(height: 10)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentDistance > allowedRadius ? "UNAVAILABLE" : "FINAL TOTAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(currentDistance > allowedRadius ? .red : AppColors.textSecondary)
                        .tracking(1)
                    
                    Text("₹\(Int(finalPrice))")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(currentDistance > allowedRadius ? .red : AppColors.primary)
                }
                
                Spacer()
                
                Button(action: onCheckout) {
                    HStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(currentDistance > allowedRadius ? "CHECK RADIUS" : "PLACE ORDER")
                                .font(.system(size: 14, weight: .black))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .black))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background {
                        if isEligible {
                            AppColors.primaryGradient
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                    .foregroundColor(isEligible ? .white : Color.gray)
                    .cornerRadius(16)
                    .shadow(color: isEligible ? AppColors.primary.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!isEligible)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(.ultraThinMaterial)
            .overlay(Rectangle().stroke(Color.white.opacity(0.5), lineWidth: 0.5), alignment: .top)
        }
    }
}
