import SwiftUI

// MARK: - Add Product View
struct AddProductView: View {
    
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var retailPrice = ""
    @State private var wholesalePrice = ""
    @State private var costPrice = ""
    @State private var imageName = ""
    @State private var selectedCategory: ProductCategory = .staples
    @State private var brand = ""
    @State private var netQuantity = ""
    @State private var description = ""
    @State private var minOrderQty = "1"
    @State private var selectedStockStatus: StockStatus = .inStock
    @State private var isTrending = false
    @State private var notifyUsers = true // New toggle
    
    // Coin Offer Logic
    @State private var coinThreshold = ""
    @State private var coinReward = ""
    @State private var coinDescription = ""
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    @State private var showSuccess = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                headerPanel
                inputGroup
                actionProtocolButton
            }
        }
        .atmosphericBackground()
        .hidesTabBar()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Protocol Executed", isPresented: $showSuccess) {
            Button("ACKNOWLEDGE") {
                clearForm()
                dismiss()
            }
        } message: {
            Text("Product has been successfully integrated into the active wholesale catalog.")
        }
    }
    
    // MARK: - View Components
    
    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "plus.square.fill")
                    .foregroundColor(AppColors.secondary)
                Text("INVENTORY INGESTION")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("New Batch Entry")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var inputGroup: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Media Asset")
            mediaSection
            
            nomenclatureSection
            economicsSection
            specificationsSection
            coinIncentiveSection
            
            Toggle(isOn: $isTrending) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MARK AS TRENDING DEAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(AppColors.secondary)
                    Text("Display this in the 'Trending Wholesale Deals' section.")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .tint(AppColors.secondary)
            .padding(.top, 12)

            Toggle(isOn: $notifyUsers) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BROADCAST TO PARTNERS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(AppColors.primary)
                    Text("Send a push alert to all users about this new SKU.")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .tint(AppColors.primary)
            .padding(.top, 12)
        }
        .padding(32)
        .background(AppColors.background)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
        .shadow(color: AppColors.primary.opacity(0.1), radius: 0, x: 4, y: 4)
        .padding(.horizontal, 24)
    }
    
    private var nomenclatureSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Nomenclature Protocol")
            VanguardInput(label: "PRODUCT IDENTIFIER (EN)", text: $name, placeholder: "e.g. Fortune Sunflower Oil", icon: "tag.fill")
        }
    }
    
    private var economicsSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Logistics & Economics")
            HStack(spacing: 16) {
                VanguardInput(label: "RETAIL (MRP)", text: $retailPrice, placeholder: "0.00", icon: "rupeesign", keyboard: .decimalPad)
                VanguardInput(label: "WHOLESALE", text: $wholesalePrice, placeholder: "0.00", icon: "rupeesign", keyboard: .decimalPad)
            }
            
            VanguardInput(label: "ADMIN COST BASIS", text: $costPrice, placeholder: "0.00", icon: "briefcase.fill", keyboard: .decimalPad)
            
            HStack(spacing: 16) {
                VanguardInput(label: "MIN ORDER QTY", text: $minOrderQty, placeholder: "1", icon: "cart.badge.plus", keyboard: .numberPad)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("CATEGORY")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(AppColors.secondary.opacity(0.8))
                    
                    Picker("", selection: $selectedCategory) {
                        ForEach(ProductCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .tint(AppColors.textPrimary)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.background)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                }
            }
        }
    }
    
    private var specificationsSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Specification Matrix")
            VanguardInput(label: "BRAND ENTITY", text: $brand, placeholder: "e.g. Fortune", icon: "building.2.fill")
            VanguardInput(label: "NET MASS / VOLUME", text: $netQuantity, placeholder: "e.g. 1L or 500g", icon: "scalemass.fill")
            VanguardInput(label: "FIELD DESCRIPTION", text: $description, placeholder: "Enter product details...", icon: "text.alignleft")
        }
    }
    
    private var coinIncentiveSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Coin Incentive Protocol (Optional)")
            
            HStack(spacing: 16) {
                VanguardInput(label: "THRESHOLD QTY", text: $coinThreshold, placeholder: "e.g. 5", icon: "cart.badge.plus", keyboard: .numberPad)
                VanguardInput(label: "REWARD COINS", text: $coinReward, placeholder: "e.g. 10", icon: "coloncurrencysign.circle.fill", keyboard: .numberPad)
            }
            
            VanguardInput(label: "INCENTIVE DESCRIPTION", text: $coinDescription, placeholder: "e.g. Buy 5 get 10 coins", icon: "sparkles")
        }
    }
    
    private var actionProtocolButton: some View {
        Button {
            HapticManager.shared.notify(.success)
            addProduct()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                Text("INITIALIZE PRODUCT SEQUENCE")
                    .font(.system(size: 14, weight: .black))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(!isValid ? AnyShapeStyle(AppColors.textPrimary.opacity(0.05)) : AnyShapeStyle(AppColors.primaryGradient))
            .foregroundColor(!isValid ? AppColors.textSecondary.opacity(0.2) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: !isValid ? .clear : AppColors.primary.opacity(0.2), radius: 0, x: 2, y: 2)
        }
        .disabled(!isValid)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    
    private var mediaSection: some View {
        HStack(spacing: 20) {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.background)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "camera.shutter.button.fill")
                                .foregroundColor(AppColors.textPrimary.opacity(0.2))
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.primary.opacity(0.15), lineWidth: 2)
            )
            .onTapGesture { showImagePicker = true }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedImage != nil ? "Image Uploaded Successfully" : "Asset identifier or upload")
                    .font(.caption2)
                    .foregroundColor(selectedImage != nil ? AppColors.success : AppColors.textSecondary)
                
                TextField("Asset Name", text: $imageName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedImage != nil ? AppColors.success.opacity(0.3) : AppColors.primary.opacity(0.15), lineWidth: 2))
                    .disabled(selectedImage != nil)
            }
        }
    }

    var isValid: Bool {
        !name.isEmpty && !retailPrice.isEmpty && !wholesalePrice.isEmpty && !costPrice.isEmpty && (selectedImage != nil || !imageName.isEmpty)
    }
    
    func addProduct() {
        guard let retail = Double(retailPrice),
              let wholesale = Double(wholesalePrice),
              let cost = Double(costPrice),
              let minQty = Int(minOrderQty) else { return }
        
        let localized: [String: String] = [AppLanguage.english.rawValue: name]
        
        let productNameForNotif = name
        
        Task {
            var finalImageString = imageName
            if let uiImage = selectedImage {
                // Aggressively resize + compress to stay well under MySQL 32MB limit
                // 400px wide @ 30% quality → typically ~50–150KB → ~200KB base64
                let targetWidth: CGFloat = 400
                let processedImage = uiImage.size.width > targetWidth
                    ? (uiImage.resized(toWidth: targetWidth) ?? uiImage)
                    : uiImage
                if let imageData = processedImage.jpegData(compressionQuality: 0.3) {
                    finalImageString = imageData.base64EncodedString()
                }
            }
            
            let newProduct = GroceryProduct(
                name: name,
                localizedNames: localized,
                retailPrice: retail,
                wholesalePrice: wholesale,
                costPrice: cost,
                image: finalImageString,
                details: GroceryProductDetails(
                    description: description,
                    category: selectedCategory,
                    brand: brand,
                    netQuantity: netQuantity
                ),
                minOrderQty: minQty,
                isTrending: isTrending,
                stockStatus: selectedStockStatus,
                coinOffer: (Int(coinThreshold) != nil && Int(coinReward) != nil) ? CoinOffer(
                    thresholdQuantity: Int(coinThreshold) ?? 0,
                    rewardCoins: Int(coinReward) ?? 0,
                    description: coinDescription.isEmpty ? "Buy \(coinThreshold) get \(coinReward) coins" : coinDescription
                ) : nil
            )
            
            await productStore.addProduct(newProduct)
            
            if notifyUsers {
                await notificationStore.sendNotification(
                    title: "New Product Arrival",
                    message: "\(productNameForNotif) is now available in our catalog. Order now for wholesale prices!",
                    type: .general,
                    userEmail: "all"
                )
            }
            
            await MainActor.run { showSuccess = true }
        }
    }
    
    func clearForm() {
        name = ""
        retailPrice = ""; wholesalePrice = ""; costPrice = ""; imageName = ""
        selectedImage = nil; brand = ""; netQuantity = ""; description = ""
        minOrderQty = "1"; selectedStockStatus = .inStock; isTrending = false
        coinThreshold = ""; coinReward = ""; coinDescription = ""
    }
}


