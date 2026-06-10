import SwiftUI

// MARK: - Home View (Modern B2B Wholesale)
struct HomeView: View {
    
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    @Binding var cartItems: [GroceryCartItem]
    @Binding var selectedLanguage: AppLanguage
    @Binding var userCoins: Int
    let userEmail: String
    @EnvironmentObject var tabBarState: TabBarState
    
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    @State private var selectedProduct: GroceryProduct? = nil
    @State private var isShowingAIChat = false
    @State private var isShowingNotifications = false
    @State private var isShowingCalculator = false
    @State private var isShowingCalendar = false
    @State private var isMenuExpanded = false
    @State private var scrollOffset = CGFloat.zero
    @State private var showInStockOnly = false
    @State private var sortByPriceAscending: Bool? = nil
    
    var analytics: BusinessAnalytics {
        productStore.calculateAnalytics(for: userEmail, currentBalance: userCoins)
    }
    
    var filteredProducts: [GroceryProduct] {
        let allProducts = productStore.products
        let categoryFiltered: [GroceryProduct]
        
        if selectedCategory == .all {
            categoryFiltered = allProducts
        } else {
            categoryFiltered = allProducts.filter { ($0.details?.category ?? .all) == selectedCategory }
        }
        
        guard !searchText.isEmpty else {
            return categoryFiltered
        }
        
        let searchLower = searchText.lowercased()
        var results = categoryFiltered.filter { product in
            let nameMatch = product.name.localizedCaseInsensitiveContains(searchLower)
            let languageKey = (selectedLanguage as? RawRepresentable)?.rawValue as? String ?? selectedLanguage.rawValue
            let localizedNameMatch = (product.localizedNames?[languageKey] ?? "").localizedCaseInsensitiveContains(searchLower)
            return nameMatch || localizedNameMatch
        }
        
        if showInStockOnly {
            results = results.filter { !$0.isOutOfStock }
        }
        
        if let ascending = sortByPriceAscending {
            results.sort { ascending ? $0.wholesalePrice < $1.wholesalePrice : $0.wholesalePrice > $1.wholesalePrice }
        }
        
        return results
    }
    
    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    
    var body: some View {
        ZStack(alignment: .center) {
            AppBackground()
            
            VStack(spacing: 0) {
                // Persistent Custom Header — fills behind status bar
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Search Section
                        searchBar
                        
                        // Professional Analytics Overview (Glanceable)
                        BusinessDashboardView(analytics: analytics)
                            .padding(.horizontal, 2)
                        
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
                                    title: selectedCategory == .all ? AppText.get("all_items", lang: selectedLanguage) : "\(selectedCategory.rawValue)",
                                    subtitle: "\(filteredProducts.count) SKUs"
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
        .toolbar(.hidden, for: .navigationBar) // Custom header — hide system nav bar
        .sheet(isPresented: $isShowingAIChat) {
            AIChatView(productStore: productStore)
                .environmentObject(tabBarState)
        }
        .sheet(isPresented: $isShowingNotifications) {
            UserNotificationsView(notificationStore: notificationStore, userEmail: userEmail)
                .environmentObject(tabBarState)
        }
        .sheet(isPresented: $isShowingCalculator) {
            CalculatorView()
        }
        .sheet(isPresented: $isShowingCalendar) {
            CalendarView()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(AppText.get("hello", lang: selectedLanguage)), \(SessionManager.shared.userName.isEmpty ? (userEmail.components(separatedBy: "@").first?.uppercased() ?? "PARTNER") : SessionManager.shared.userName.uppercased())")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1.0)
                
                Text(AppText.get("vsn_home", lang: selectedLanguage))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(AppColors.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10))
                    Text(AppText.get("hub_location", lang: selectedLanguage))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppColors.textSecondary.opacity(0.8))
            }
            
            Spacer()
            
            HStack(spacing: 15) {
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
                        .font(.system(size: 12, weight: .bold))
                        .padding(8)
                        .background(Color.black.opacity(0.05))
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
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .padding(.top, 12)
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(Rectangle().fill(Color.black.opacity(0.05)).frame(height: 0.5), alignment: .bottom)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search Input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                
                TextField(AppText.get("search_placeholder", lang: selectedLanguage), text: $searchText)
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .frame(height: 50) // Explicit matched height
            .background(Color.black.opacity(0.04))
            .cornerRadius(15)
            
            // Filter Menu
            Menu {
                Button(action: { showInStockOnly.toggle() }) {
                    Label(showInStockOnly ? AppText.get("all_items", lang: selectedLanguage) : AppText.get("out_of_stock_only", lang: selectedLanguage), systemImage: showInStockOnly ? "eye" : "eye.slash")
                }
                
                Divider()
                
                Button(action: { sortByPriceAscending = true }) {
                    Label(AppText.get("price_low_high", lang: selectedLanguage), systemImage: "arrow.up")
                }
                
                Button(action: { sortByPriceAscending = false }) {
                    Label(AppText.get("price_high_low", lang: selectedLanguage), systemImage: "arrow.down")
                }
                
                Button(role: .destructive, action: { 
                    sortByPriceAscending = nil
                    showInStockOnly = false
                }) {
                    Label(AppText.get("reset_filters", lang: selectedLanguage), systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50) // Explicit matched height
                    .background(AppColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
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
                Text(AppText.get("live_trends", lang: selectedLanguage))
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
                    ForEach(productStore.calculateMarketTrends()) { trend in
                        TickerItem(label: trend.label, value: trend.value, color: trend.color)
                    }
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
            HStack(spacing: 12) {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                        HapticManager.shared.trigger(.light)
                    }) {
                        Text(category == .all ? AppText.get("all_category", lang: selectedLanguage) : AppText.get("cat_\(category.rawValue.lowercased().components(separatedBy: " ").first!)", lang: selectedLanguage))
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? AnyShapeStyle(AppColors.secondaryGradient) : AnyShapeStyle(Color.black.opacity(0.04)))
                            .foregroundColor(selectedCategory == category ? .white : AppColors.textPrimary.opacity(0.7))
                            .clipShape(Capsule())
                            .shadow(color: selectedCategory == category ? AppColors.secondary.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 4)
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
                VStack(spacing: 16) {
                    if isMenuExpanded {
                        // Calculator Button
                        ActionButton(icon: "number.square.fill", color: .orange) {
                            isShowingCalculator = true
                            isMenuExpanded = false
                        }
                        .transition(.scale.combined(with: .opacity))
                        
                        // Calendar Button
                        ActionButton(icon: "calendar", color: .purple) {
                            isShowingCalendar = true
                            isMenuExpanded = false
                        }
                        .transition(.scale.combined(with: .opacity))
                        
                        // AI Chat Button
                        ActionButton(icon: "sparkles", color: .blue) {
                            isShowingAIChat = true
                            isMenuExpanded = false
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Main Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isMenuExpanded.toggle()
                        }
                        HapticManager.shared.trigger(.medium)
                    }) {
                        Image(systemName: isMenuExpanded ? "xmark" : "plus")
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 60, height: 60)
                            .background(AppColors.primaryGradient)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
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

// MARK: - ActionButton Component
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.trigger(.light)
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .frame(width: 48, height: 48)
                .background(color)
                .foregroundColor(.white)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
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

