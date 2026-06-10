import SwiftUI

// MARK: - Home View (Modern B2B Wholesale)
struct HomeView: View {
    
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    @Binding var cartItems: [GroceryCartItem]
    @Binding var selectedLanguage: AppLanguage
    let userEmail: String
    @EnvironmentObject var tabBarState: TabBarState
    
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    @State private var selectedProduct: GroceryProduct? = nil
    @State private var isShowingAIChat = false
    @State private var isShowingNotifications = false
    @State private var scrollOffset = CGFloat.zero
    
    var filteredProducts: [GroceryProduct] {
        let allProducts = productStore.products
        let categoryFiltered: [GroceryProduct]
        
        if selectedCategory == .all {
            categoryFiltered = allProducts
        } else {
            categoryFiltered = allProducts.filter { $0.details!.category == selectedCategory }
        }
        
        guard !searchText.isEmpty else {
            return categoryFiltered
        }
        
        let searchLower = searchText.lowercased()
        return categoryFiltered.filter { product in
            let nameMatch = product.name.localizedCaseInsensitiveContains(searchLower)
            let localizedNameMatch = product.localizedNames![selectedLanguage]?.localizedCaseInsensitiveContains(searchLower) ?? false
            return nameMatch || localizedNameMatch
        }
    }
    
    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
    var body: some View {
        ZStack(alignment: .center) {
            AppBackground()
            
            VStack(spacing: 0) {
                // Persistent Custom Header
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Search Section
                        searchBar
                        
                        // Professional Analytics Overview (Glanceable)
                        BusinessDashboardView(analytics: productStore.calculateAnalytics(for: userEmail, currentBalance: SessionManager.shared.userCoins))
                            .padding(.horizontal, 20)
                        
                        // Market Trends Ticker (Simplified)
                        marketTrendsTicker
                        
                        // Categories
                        categoryFilter
                        
                        // Main Content
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Featured Section
                            if selectedCategory == .all && searchText.isEmpty {
                                sectionHeader(title: "Trending Wholesale Deals", subtitle: "High demand inventory")
                                trendingSection
                            }
                            
                            // Inventory Grid
                            VStack(alignment: .leading, spacing: 16) {
                                sectionHeader(
                                    title: selectedCategory == .all ? "Main Catalog" : "\(selectedCategory.rawValue) Inventory",
                                    subtitle: "\(filteredProducts.count) SKUs available"
                                )
                                
                                mainItemsGrid
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, tabBarState.isHidden ? 20 : 130)
                }
            }
            
            // Strategic AI Advisor (Modern Floating Button)
            aiAdvisorButton
        }
        .navigationDestination(item: $selectedProduct) { product in
            ProductDetailsView(product: product, selectedLanguage: selectedLanguage, addToCartAction: addToCart)
        }
        .sheet(isPresented: $isShowingAIChat) {
            AIChatView(productStore: productStore)
                .environmentObject(tabBarState)
        }
        .sheet(isPresented: $isShowingNotifications) {
            UserNotificationsView(notificationStore: notificationStore, userEmail: userEmail)
                .environmentObject(tabBarState)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("HELLO, \(SessionManager.shared.userName.isEmpty ? (userEmail.components(separatedBy: "@").first?.uppercased() ?? "PARTNER") : SessionManager.shared.userName.uppercased())")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("V.S.N. HOME")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(AppColors.primary)
                    .tracking(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text("Vijayawada Hub")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Language Switcher
                Menu {
                    ForEach(AppLanguage.allCases) { lang in
                        Button(lang.rawValue) { 
                            selectedLanguage = lang
                            HapticManager.shared.trigger(.light)
                        }
                    }
                } label: {
                    Text(selectedLanguage.rawValue.prefix(2).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(8)
                        .background(Color(UIColor.secondarySystemFill))
                        .clipShape(Circle())
                }
                
                // Notifications
                Button(action: {
                    isShowingNotifications = true
                    HapticManager.shared.trigger(.light)
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if notificationStore.unreadCount > 0 {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                Text("\(notificationStore.unreadCount)")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 14, height: 14)
                            .offset(x: 6, y: -6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 44) + 12)
        .padding(.bottom, 12)
        .background(AppColors.surfaceLight)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private var searchBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                TextField("Search brand or product...", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground).opacity(0.7))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
            )
            
            Button(action: { 
                HapticManager.shared.trigger(.light)
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 22)
    }
    
    private var marketTrendsTicker: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .glow(color: .white, radius: 2)
                Text("LIVE TRENDS")
                    .font(.system(size: 8, weight: .black))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.primaryGradient)
            .clipShape(Capsule())
            .padding(.trailing, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    TickerItem(label: "Sugar", value: "↑ 2%", color: .green)
                    TickerItem(label: "Oil", value: "↓ 1%", color: .red)
                    TickerItem(label: "Rice", value: "Stable", color: AppColors.textSecondary)
                    TickerItem(label: "Atta", value: "↑ 5%", color: .green)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            BlurView(style: .systemUltraThinMaterialLight)
                .opacity(0.4)
                .overlay(Rectangle().stroke(Color.black.opacity(0.05), lineWidth: 0.5), alignment: .bottom)
        )
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        HapticManager.shared.trigger(.light)
                    }) {
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? AppColors.primary : Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(selectedCategory == category ? .white : AppColors.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCategory == category ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var trendingSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(productStore.products.filter { $0.isTrending }) { product in
                    TrendingProductCard(product: product, selectedLanguage: selectedLanguage, cartItems: $cartItems)
                    .onTapGesture {
                        selectedProduct = product
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var mainItemsGrid: some View {
        Group {
            if filteredProducts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "basket")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                    Text("No products found in this category.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredProducts) { product in
                        ProductCard(product: product, selectedLanguage: selectedLanguage, cartItems: $cartItems)
                        .onTapGesture {
                            selectedProduct = product
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var aiAdvisorButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    isShowingAIChat = true
                    HapticManager.shared.trigger(.medium)
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22))
                        .frame(width: 56, height: 56)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, tabBarState.isHidden ? 20 : 120)
            }
        }
    }
    
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 20)
    }
    
    private func addToCart(_ product: GroceryProduct) {
        guard !product.isOutOfStock else { return }
        HapticManager.shared.notify(.success)
        if let index = cartItems.firstIndex(where: { $0.product.name == product.name }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(GroceryCartItem(product: product, quantity: 1))
        }
    }
}

// MARK: - TickerItem
struct TickerItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Text(value)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(color)
        }
    }
}

