import SwiftUI
import Combine

// MARK: - Main App Structure with Tabs
struct GroceryAppView: View {
    
    @StateObject private var productStore = GroceryProductStore() // Source of truth for products
    @StateObject private var notificationStore = NotificationStore() // New shared notifications
    @StateObject private var tabBarState = TabBarState() // Controls custom bottom bar visibility
    @State private var selectedTab: Tab = .home
    @State private var cartItems: [GroceryCartItem] = []
    @State private var userCoins: Int = SessionManager.shared.userCoins
    @Binding var selectedLanguage: AppLanguage
    @State private var userAddress: String = "" // User's delivery address
    @State private var userLatitude: Double = 0
    @State private var userLongitude: Double = 0
    @State private var selectedOffer: BulkOffer? = nil // Shared offer state
    @State private var isShowingLanguageInitial = true // Show language picker once after login
    @State private var showReferralDashboard: Bool = false
    @AppStorage("app_color_scheme") private var appColorScheme: String = "light"
    
    @Binding var isLoggedIn: Bool
    @Binding var isAdmin: Bool
    @Binding var userEmail: String
    
    @Namespace private var tabNamespace // For liquid highlight animation
    
    init(isLoggedIn: Binding<Bool>, isAdmin: Binding<Bool>, userEmail: Binding<String>, selectedLanguage: Binding<AppLanguage>) {
        self._isLoggedIn = isLoggedIn
        self._isAdmin = isAdmin
        self._userEmail = userEmail
        self._selectedLanguage = selectedLanguage
        
        // 🛠️ CRITICAL FIX: Explicitly wipe native TabBar to prevent "ghosting"
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().backgroundColor = .clear
        
        let hasSelected = UserDefaults.standard.bool(forKey: "language_selected_\(userEmail.wrappedValue)")
        self._isShowingLanguageInitial = State(initialValue: !hasSelected)
    }
    
    enum Tab: String, CaseIterable {
        case home, offers, cart, profile
    }
    
    @ViewBuilder
    var body: some View {
        Group {
            if isAdmin {
                AdminTabView(productStore: productStore, notificationStore: notificationStore, selectedLanguage: $selectedLanguage) {
                    withAnimation {
                        SessionManager.shared.clearSession()
                        isAdmin = false
                        isLoggedIn = false
                    }
                }
            } else {
                ZStack(alignment: .bottom) {
                    userTabInterface
                    
                    if !tabBarState.isHidden {
                        liquidTabBar
                            .zIndex(100) // Ensure it stays on top
                    }
                }
            }
        }
        .preferredColorScheme(colorSchemeFromString(appColorScheme))
        .environmentObject(tabBarState)
        .background(AppBackground())

        .accentColor(AppColors.primary) // Trust Blue as primary accent
        .sheet(isPresented: $isShowingLanguageInitial) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage, isPresented: $isShowingLanguageInitial, userEmail: userEmail)
                .interactiveDismissDisabled()
        }
        .onAppear {
            productStore.loadLocalData(for: isAdmin ? nil : userEmail)
            Task {
                await productStore.fetchProducts() // Ensure latest catalog is fetched
                await productStore.fetchOrders(email: isAdmin ? nil : userEmail, isAdmin: isAdmin)
                await notificationStore.fetchNotifications(userEmail: userEmail)
                // Sync user fields with persisted session
                self.userCoins = SessionManager.shared.userCoins
                self.userAddress = SessionManager.shared.userAddress
                notificationStore.startPolling(userEmail: userEmail)
            }
        }
        .onChange(of: userCoins) { newValue in
            SessionManager.shared.updateCoins(newValue)
        }
        .onReceive(SessionManager.shared.$userCoins) { newValue in
            if userCoins != newValue {
                userCoins = newValue
            }
        }
        .onReceive(SessionManager.shared.$userAddress) { newValue in
            if userAddress != newValue {
                userAddress = newValue
            }
        }
        .onDisappear {
            notificationStore.stopPolling()
        }
        .onChange(of: userEmail) { newEmail in
            // A different user has logged in – wipe all per-session state
            cartItems = []
            userAddress = ""
            userLatitude = 0
            userLongitude = 0
            selectedOffer = nil
            // Load local data for the new user immediately
            productStore.loadLocalData(for: isAdmin ? nil : newEmail)
            // Re-fetch for the newly logged-in user
            Task {
                await productStore.fetchOrders(email: isAdmin ? nil : newEmail, isAdmin: isAdmin)
                await notificationStore.fetchNotifications(userEmail: newEmail)
                userCoins = SessionManager.shared.userCoins
                userAddress = SessionManager.shared.userAddress
                notificationStore.startPolling(userEmail: newEmail)
            }
        }
    }
    
    private func colorSchemeFromString(_ value: String) -> ColorScheme? {
        switch value {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil // system default
        }
    }
    
    private var userTabInterface: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView(productStore: productStore, notificationStore: notificationStore, cartItems: $cartItems, selectedLanguage: $selectedLanguage, userCoins: $userCoins, userEmail: userEmail)
            }
            .environmentObject(tabBarState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .tag(Tab.home)
            
            // Offers Tab
            NavigationStack {
                OffersView(productStore: productStore, selectedLanguage: selectedLanguage, selectedOffer: $selectedOffer, selectedTab: $selectedTab)
            }
            .environmentObject(tabBarState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .tag(Tab.offers)
            
            // Cart Tab
            NavigationStack {
                CartView(productStore: productStore, cartItems: $cartItems, userCoins: $userCoins, orders: $productStore.orders, selectedTab: $selectedTab, userAddress: $userAddress, userLatitude: $userLatitude, userLongitude: $userLongitude, selectedOffer: $selectedOffer, selectedLanguage: selectedLanguage, userEmail: userEmail)
            }
            .environmentObject(tabBarState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .tag(Tab.cart)
            
            // Profile Tab
            NavigationStack {
                ProfileView(coins: $userCoins, orders: productStore.orders, userAddress: $userAddress, userLatitude: $userLatitude, userLongitude: $userLongitude, selectedTab: $selectedTab, isLoggedIn: $isLoggedIn, selectedLanguage: $selectedLanguage, userEmail: $userEmail, appColorScheme: $appColorScheme, productStore: productStore, notificationStore: notificationStore)
            }
            .environmentObject(tabBarState)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .tag(Tab.profile)
        }
    }

    private var liquidTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    icon: tabIcon(for: tab),
                    label: tabLabel(for: tab),
                    selectedTab: $selectedTab,
                    namespace: tabNamespace,
                    activeColor: AppColors.primary,
                    badge: tab == .cart ? cartItems.count : 0
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background {
            ZStack {
                // Main Capsule (Solid-ish to hide ghosts)
                Capsule()
                    .fill(AppColors.surfaceLight.opacity(0.98))
                    .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
                
                // Material Blur Overlay
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                
                // Border & Inner Glow
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24) // Precise floating height
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func tabIcon(for tab: GroceryAppView.Tab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .offers: return "sparkles"
        case .cart: return "cart.fill"
        case .profile: return "person.2.fill"
        }
    }
    
    private func tabLabel(for tab: GroceryAppView.Tab) -> String {
        switch tab {
        case .home: return AppText.get("tab_wholesale", lang: selectedLanguage)
        case .offers: return AppText.get("tab_deals", lang: selectedLanguage)
        case .cart: return AppText.get("tab_cart", lang: selectedLanguage)
        case .profile: return AppText.get("profile_title", lang: selectedLanguage)
        }
    }
    
    private func tabColor(_ tab: GroceryAppView.Tab) -> Color {
        return AppColors.primary
    }
}

struct TabButton: View {
    let tab: GroceryAppView.Tab
    let icon: String
    let label: String
    @Binding var selectedTab: GroceryAppView.Tab
    var namespace: Namespace.ID
    let activeColor: Color
    var badge: Int = 0
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0)) {
                selectedTab = tab
            }
            HapticManager.shared.trigger(.light)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(activeColor.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "tabHighlight", in: namespace)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.6))
                        .frame(width: 28, height: 28)
                    
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
                .frame(height: 44)
                
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.7))
                    .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: AppLanguage
    @Binding var isPresented: Bool
    let userEmail: String
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simplified Header
                VStack(spacing: 12) {
                    Image(systemName: "globe.central.south.asia.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppColors.primary.opacity(0.8))
                        .padding(.top, 40)
                    
                    Text("Select App Language")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Choose your preferred language for business logistics.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 32)
                
                // Language Grid (Neat 2x2 Layout)
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(AppLanguage.allCases) { language in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { 
                                    selectedLanguage = language 
                                }
                                HapticManager.shared.trigger(.light)
                            }) {
                                VStack(spacing: 8) {
                                    Text(language.rawValue)
                                        .font(.system(size: 15, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(selectedLanguage == language ? .white : AppColors.textPrimary)
                                    
                                    if selectedLanguage == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 100)
                                .background(selectedLanguage == language ? AnyShapeStyle(AppColors.primaryGradient) : AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground)))
                                .cornerRadius(16)
                                .shadow(color: selectedLanguage == language ? AppColors.primary.opacity(0.3) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedLanguage == language ? Color.white.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Confirm
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "language_selected_\(userEmail)")
                    UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "user_language_\(userEmail)")
                    isPresented = false
                    HapticManager.shared.trigger(.medium)
                }) {
                    Text("CONFIRM SELECTION")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(24)
                }
            }
        }
    }
}

