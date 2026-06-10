import SwiftUI

// MARK: - Add Product View
struct AddProductView: View {
    
    @ObservedObject var productStore: GroceryProductStore
    
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
    
    // Coin Offer Logic
    @State private var coinThreshold = ""
    @State private var coinReward = ""
    @State private var coinDescription = ""
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    @State private var nameHindi = ""
    @State private var nameTelugu = ""
    @State private var nameKannada = ""
    
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
            Button("ACKNOWLEDGE") { clearForm() }
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
            VanguardInput(label: "PRODUCT IDENTIFIER (EN)", text: $name, icon: "tag.fill")
            
            HStack(spacing: 16) {
                VanguardInput(label: "HINDI", text: $nameHindi, icon: "character.book.closed.fill")
                VanguardInput(label: "TELUGU", text: $nameTelugu, icon: "character.book.closed.fill")
            }
        }
    }
    
    private var economicsSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Logistics & Economics")
            HStack(spacing: 16) {
                VanguardInput(label: "RETAIL (MRP)", text: $retailPrice, icon: "rupeesign", keyboard: .decimalPad)
                VanguardInput(label: "WHOLESALE", text: $wholesalePrice, icon: "rupeesign", keyboard: .decimalPad)
            }
            
            VanguardInput(label: "ADMIN COST BASIS", text: $costPrice, icon: "briefcase.fill", keyboard: .decimalPad)
            
            HStack(spacing: 16) {
                VanguardInput(label: "MIN ORDER QTY", text: $minOrderQty, icon: "cart.badge.plus", keyboard: .numberPad)
                
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
            VanguardInput(label: "BRAND ENTITY", text: $brand, icon: "building.2.fill")
            VanguardInput(label: "NET MASS / VOLUME", text: $netQuantity, icon: "scalemass.fill")
            VanguardInput(label: "FIELD DESCRIPTION", text: $description, icon: "text.alignleft")
        }
    }
    
    private var coinIncentiveSection: some View {
        VStack(spacing: 24) {
            SectionHeader(title: "Coin Incentive Protocol (Optional)")
            
            HStack(spacing: 16) {
                VanguardInput(label: "THRESHOLD QTY", text: $coinThreshold, icon: "cart.badge.plus", keyboard: .numberPad)
                VanguardInput(label: "REWARD COINS", text: $coinReward, icon: "coloncurrencysign.circle.fill", keyboard: .numberPad)
            }
            
            VanguardInput(label: "INCENTIVE DESCRIPTION", text: $coinDescription, icon: "sparkles")
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
                Text("Asset identifier or upload")
                    .font(.caption2)
                    .foregroundColor(AppColors.textSecondary)
                
                TextField("Asset Name", text: $imageName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
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
        
        var localized: [AppLanguage: String] = [.english: name]
        if !nameHindi.isEmpty { localized[.hindi] = nameHindi }
        if !nameTelugu.isEmpty { localized[.telugu] = nameTelugu }
        if !nameKannada.isEmpty { localized[.kannada] = nameKannada }
        
        Task {
            var finalImageString = imageName
            if let uiImage = selectedImage {
                let processedImage = uiImage.size.width > 800 ? (uiImage.resized(toWidth: 800) ?? uiImage) : uiImage
                if let imageData = processedImage.jpegData(compressionQuality: 0.6) {
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
            await MainActor.run { showSuccess = true }
        }
    }
    
    func clearForm() {
        name = ""; nameHindi = ""; nameTelugu = ""; nameKannada = ""
        retailPrice = ""; wholesalePrice = ""; costPrice = ""; imageName = ""
        selectedImage = nil; brand = ""; netQuantity = ""; description = ""
        minOrderQty = "1"; selectedStockStatus = .inStock; isTrending = false
        coinThreshold = ""; coinReward = ""; coinDescription = ""
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 8, weight: .black))
            .tracking(1)
            .foregroundColor(AppColors.textSecondary)
            .padding(.top, 8)
    }
}

struct VanguardInput: View {
    let label: String
    @Binding var text: String
    let icon: String
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(AppColors.secondary)
            
            TextField("", text: $text)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding(16)
                .background(AppColors.background)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                .keyboardType(keyboard)
        }
    }
}
