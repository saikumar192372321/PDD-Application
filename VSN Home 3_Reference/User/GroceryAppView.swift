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
    @State private var selectedLanguage: AppLanguage = .english
    @State private var userAddress: String = "" // User's delivery address
    @State private var userLatitude: Double = 0
    @State private var userLongitude: Double = 0
    @State private var selectedOffer: BulkOffer? = nil // Shared offer state
    @State private var isShowingLanguageInitial = true // Show language picker once after login
    @AppStorage("app_color_scheme") private var appColorScheme: String = "light"
    
    @Binding var isLoggedIn: Bool
    @Binding var isAdmin: Bool
    @Binding var userEmail: String
    
    @Namespace private var tabNamespace // For liquid highlight animation
    
    init(isLoggedIn: Binding<Bool>, isAdmin: Binding<Bool>, userEmail: Binding<String>) {
        self._isLoggedIn = isLoggedIn
        self._isAdmin = isAdmin
        self._userEmail = userEmail
        
        let hasSelected = UserDefaults.standard.bool(forKey: "language_selected_\(userEmail.wrappedValue)")
        self._isShowingLanguageInitial = State(initialValue: !hasSelected)
        
        if let savedLangRaw = UserDefaults.standard.string(forKey: "user_language_\(userEmail.wrappedValue)"),
           let savedLang = AppLanguage(rawValue: savedLangRaw) {
            self._selectedLanguage = State(initialValue: savedLang)
        } else {
            self._selectedLanguage = State(initialValue: .english)
        }
    }
    
    enum Tab: String, CaseIterable {
        case home, offers, cart, profile, admin
    }
    
    @ViewBuilder
    var body: some View {
        Group {
            if isAdmin {
                AdminTabView(productStore: productStore, notificationStore: notificationStore) {
                    withAnimation {
                        SessionManager.shared.clearSession()
                        isAdmin = false
                        isLoggedIn = false
                    }
                }
            } else {
                userTabInterface
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
        ZStack(alignment: .bottom) {
            userTabView
            
            if !tabBarState.isHidden {
                liquidTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private var userTabView: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                HomeView(productStore: productStore, notificationStore: notificationStore, cartItems: $cartItems, selectedLanguage: $selectedLanguage, userEmail: userEmail)
            }
            .environmentObject(tabBarState)
            .tag(Tab.home)
            
            // Offers Tab
            NavigationStack {
                OffersView(productStore: productStore, selectedLanguage: selectedLanguage, selectedOffer: $selectedOffer, selectedTab: $selectedTab)
            }
            .environmentObject(tabBarState)
            .tag(Tab.offers)
            
            // Cart Tab
            NavigationStack {
                CartView(productStore: productStore, cartItems: $cartItems, userCoins: $userCoins, orders: $productStore.orders, selectedTab: $selectedTab, userAddress: $userAddress, userLatitude: $userLatitude, userLongitude: $userLongitude, selectedOffer: $selectedOffer, selectedLanguage: selectedLanguage, userEmail: userEmail)
            }
            .environmentObject(tabBarState)
            .tag(Tab.cart)
            
            // Profile Tab
            NavigationStack {
                ProfileView(coins: $userCoins, orders: productStore.orders, userAddress: $userAddress, userLatitude: $userLatitude, userLongitude: $userLongitude, selectedTab: $selectedTab, isLoggedIn: $isLoggedIn, selectedLanguage: $selectedLanguage, userEmail: $userEmail, appColorScheme: $appColorScheme, productStore: productStore, notificationStore: notificationStore)
            }
            .environmentObject(tabBarState)
            .tag(Tab.profile)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var liquidTabBar: some View {
        ZStack {
            // Shared Liquid Highlight (Hyper-Glassy Bubble)
            // Moving Bubble (Target)
            Capsule()
                .fill(.ultraThickMaterial)
                .frame(width: 72, height: 42)
                .matchedGeometryEffect(id: "liquid_bubble", in: tabNamespace, isSource: false)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .overlay {
                    Capsule()
                        .stroke(AppColors.primary.opacity(0.15), lineWidth: 0.5)
                }
            .padding(.horizontal, 8)
            
            HStack(spacing: 0) {
                TabButton(tab: .home, icon: "house.fill", label: "Wholesale", selectedTab: $selectedTab, namespace: tabNamespace, activeColor: AppColors.primary)
                TabButton(tab: .offers, icon: "square.grid.2x2.fill", label: "New", selectedTab: $selectedTab, namespace: tabNamespace, activeColor: AppColors.primary)
                TabButton(tab: .cart, icon: "cart.fill", label: "Cart", selectedTab: $selectedTab, namespace: tabNamespace, activeColor: AppColors.primary, badge: cartItems.count)
                TabButton(tab: .profile, icon: "person.2.fill", label: "Account", selectedTab: $selectedTab, namespace: tabNamespace, activeColor: AppColors.primary)
            }
        }
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.4), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func tabColor(_ tab: Tab) -> Color {
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0)) {
                selectedTab = tab
            }
            HapticManager.shared.trigger(.light)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Spacer for MatchedGeometry target
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 70, height: 44)
                        .matchedGeometryEffect(id: "liquid_bubble", in: namespace, isSource: isSelected)

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.6))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                    
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(4)
                            .frame(minWidth: 15, minHeight: 15)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -10)
                    }
                }
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? activeColor : .secondary.opacity(0.6))
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
                
                // Language Grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(AppLanguage.allCases) { language in
                            Button(action: {
                                withAnimation { selectedLanguage = language }
                                HapticManager.shared.trigger(.light)
                            }) {
                                HStack(spacing: 12) {
                                    Text(language.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedLanguage == language ? AppColors.primary : AppColors.textPrimary)
                                    Spacer()
                                    if selectedLanguage == language {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.primary)
                                    }
                                }
                                .padding(16)
                                .background(selectedLanguage == language ? AppColors.primary.opacity(0.08) : Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedLanguage == language ? AppColors.primary : Color.black.opacity(0.05), lineWidth: 1)
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
