import SwiftUI

// MARK: - Profile View (Refined B2B Business Profile)
struct ProfileView: View {
    @Binding var coins: Int
    var orders: [Order]
    @Binding var userAddress: String
    @Binding var userLatitude: Double
    @Binding var userLongitude: Double
    @Binding var selectedTab: GroceryAppView.Tab
    @Binding var isLoggedIn: Bool
    @Binding var selectedLanguage: AppLanguage
    @Binding var userEmail: String
    @Binding var appColorScheme: String
    
    @EnvironmentObject var tabBarState: TabBarState
    
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage = ""
    @State private var showAdminPortal = false
    @State private var showReferralDashboard = false
    
    // Inject notification and product stores if needed via Environment or Observed
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                
                // 1. Profile Header
                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: AppColors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
                    
                    VStack(spacing: 6) {
                        Text(SessionManager.shared.userName.isEmpty ? (userEmail.components(separatedBy: "@").first?.uppercased() ?? "PARTNER") : SessionManager.shared.userName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if !SessionManager.shared.userBusinessName.isEmpty {
                            Text(SessionManager.shared.userBusinessName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        HStack(spacing: 8) {
                            Text("Wholesale Partner")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(Capsule())
                            
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                Text("Verified")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(AppColors.success)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColors.success.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.top, 10)
                
                // 2. Business Metrics
                HStack(spacing: 16) {
                    MetricInfoCard(
                        title: "Partner Coins",
                        value: "\(coins)",
                        icon: "coloncurrencysign.circle.fill",
                        color: .orange
                    )
                    
                    MetricInfoCard(
                        title: "Total Orders",
                        value: "\(orders.count)",
                        icon: "shippingbox.fill",
                        color: AppColors.primary
                    )
                }
                .padding(.horizontal, 22)
                
                // 3. Menu Options
                VStack(spacing: 1) {
                    NavigationLink(destination: MyOrdersView(orders: orders, selectedLanguage: selectedLanguage)) {
                        MenuRow(title: "Order History", icon: "list.clipboard.fill", color: .blue)
                    }
                    
                    NavigationLink(destination: MyAddressView(userAddress: $userAddress, latitude: $userLatitude, longitude: $userLongitude)) {
                        MenuRow(title: "Shipping Address", icon: "map.fill", color: .green)
                    }
                    
                    NavigationLink(destination: AccountSecurityView(userEmail: $userEmail)) {
                        MenuRow(title: "Security Settings", icon: "shield.lefthalf.filled", color: .purple)
                    }
                    
                    NavigationLink(destination: HelpDeskView()) {
                        MenuRow(title: "Help Desk Support", icon: "headphones", color: .orange)
                    }
                    
                    Button(action: {
                        HapticManager.shared.trigger(.light)
                        showReferralDashboard = true
                    }) {
                        MenuRow(title: "Refer & Earn Coins", icon: "gift.fill", color: .pink)
                    }
                    
                    Button(action: { 
                        HapticManager.shared.trigger(.light)
                        showAdminPortal = true 
                    }) {
                        MenuRow(title: "Admin Management Hub", icon: "shield.badge.checkmark", color: .red)
                    }
                }
                .background(AppColors.surfaceLight)
                .cornerRadius(16)
                .padding(.horizontal, 22)
                
                // 4. Preferences (Appearance & Language)
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Preferences")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 30)
                    
                    VStack(spacing: 1) {
                        // Appearance
                        HStack {
                            Label("Theme", systemImage: appColorScheme == "dark" ? "moon.fill" : "sun.max.fill")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Picker("", selection: $appColorScheme) {
                                Text("Light").tag("light")
                                Text("Dark").tag("dark")
                                Text("Auto").tag("system")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                        .padding(16)
                        .background(AppColors.surfaceLight)
                        
                        // Language
                        HStack {
                            Label("Language", systemImage: "globe")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Menu {
                                ForEach(AppLanguage.allCases) { lang in
                                    Button(lang.rawValue) { selectedLanguage = lang }
                                }
                            } label: {
                                Text(selectedLanguage.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(16)
                        .background(AppColors.surfaceLight)
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 22)
                }
                
                // 5. Destructive Actions
                VStack(spacing: 12) {
                    Button(action: { showLogoutConfirmation = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                        }
                        .foregroundColor(.red)
                        .padding(16)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(14)
                    }
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.xmark")
                            Text("Delete Business Account")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .foregroundColor(AppColors.textSecondary)
                        .padding(16)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 22)
                }
                .padding(.vertical, 16)
                .padding(.bottom, tabBarState.isHidden ? 20 : 130)
            }
        }
        .navigationTitle("My Business")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { 
                SessionManager.shared.clearSession()
                isLoggedIn = false 
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This action cannot be undone. All orders and credits will be lost.")
        }
        .fullScreenCover(isPresented: $showAdminPortal) {
            AdminLoginView(
                isLoggedIn: $isLoggedIn,
                productStore: productStore,
                notificationStore: notificationStore,
                onDismiss: { showAdminPortal = false }
            )
            .environmentObject(TabBarState()) // Critical injection for admin portal navigation
        }
        .sheet(isPresented: $showReferralDashboard) {
            ReferralDashboardView()
        }
    }
    
    private func deleteAccount() {
        isDeletingAccount = true
        deleteErrorMessage = ""
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL + "delete_account.php") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                request.httpBody = try JSONSerialization.data(withJSONObject: ["email": userEmail])
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
                await MainActor.run {
                    isDeletingAccount = false
                    if response.status == "success" { 
                        SessionManager.shared.clearSession()
                        isLoggedIn = false 
                    }
                }
            } catch { await MainActor.run { isDeletingAccount = false } }
        }
    }
}

// MARK: - Components

struct MetricInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

struct MenuRow: View {
    let title: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32)
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary.opacity(0.4))
        }
        .padding(16)
        .background(AppColors.surfaceLight)
    }
}

// MARK: - Address & Order Sub-views (Refined)

struct MyAddressView: View {
    @Binding var userAddress: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @State private var shopName = ""
    @State private var shopNumber = ""
    @State private var street = ""
    @State private var landmark = ""
    @State private var pincode = ""
    @State private var city = ""
    @State private var showMapPicker = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Inventory Destination")
                        .font(.system(size: 20, weight: .bold))
                    Text("Set your primary warehouse or shop delivery details.")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    AddressEntryField(label: "Shop / Business Name", text: $shopName)
                    AddressEntryField(label: "Unit Number", text: $shopNumber)
                    AddressEntryField(label: "Street Address", text: $street)
                    AddressEntryField(label: "Landmark (Optional)", text: $landmark)
                    HStack {
                        AddressEntryField(label: "City", text: $city)
                        AddressEntryField(label: "Pincode", text: $pincode)
                    }
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    saveAddress()
                    dismiss()
                }) {
                    Text("Update Address")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .padding(.top, 20)
        }
        .navigationTitle("Business Address")
        .onAppear { parseAddress() }
    }
    
    private func saveAddress() {
        userAddress = [shopName, shopNumber, street, landmark, city, pincode].filter { !$0.isEmpty }.joined(separator: ", ")
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
}

struct AddressEntryField: View {
    let label: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            TextField("", text: $text)
                .padding(14)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(10)
        }
    }
}

struct MyOrdersView: View {
    let orders: [Order]
    let selectedLanguage: AppLanguage
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if orders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        Text("No Order History")
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(orders) { order in
                        NavigationLink(destination: OrderTrackingView(order: order, selectedLanguage: selectedLanguage)) {
                            OrderSnippetCard(order: order)
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Order History")
    }
}

struct OrderSnippetCard: View {
    let order: Order
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(order.id.prefix(8).uppercased())")
                    .font(.system(size: 14, weight: .bold))
                Text(order.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(Int(order.total))")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(AppColors.primary)
                Text(order.status.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(AppColors.surfaceLight)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Dummy placeholders for missing views to ensure compilation
struct AccountSecurityView: View {
    @Binding var userEmail: String
    var body: some View { Text("Security Settings").navigationTitle("Security") }
}

struct HelpDeskView: View {
    @State private var supportEmail = "support@vsn-home.in"
    @State private var supportWhatsApp = "+91 9059270899"
    @State private var isLoading = true
    
    var body: some View { 
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "headphones.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(AppColors.primary)
                    .padding(.top, 40)
                
                Text("VSN Home Partner Support")
                    .font(.system(size: 22, weight: .bold))
                
                Text("Our B2B support team is available 24/7. Reach out via email or phone for immediate assistance with bulk orders, returns, or account issues.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if isLoading {
                    ProgressView()
                        .padding(.top, 20)
                } else {
                    VStack(spacing: 16) {
                        Button(action: {
                            let subject = "VSN Home Support Request".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            let body = "Hello Support Team,\n\nI am facing an issue and need assistance.\n\nDetails:\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "mailto:\(supportEmail)?subject=\(subject)&body=\(body)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            ContactRow(icon: "envelope.fill", title: "Email Support", value: supportEmail)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            let text = "Hello Admin, I am facing an issue and need support."
                            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            let digits = supportWhatsApp.filter("0123456789".contains)
                            if let url = URL(string: "https://wa.me/\(digits)?text=\(encodedText)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            ContactRow(icon: "message.fill", title: "WhatsApp Hub", value: supportWhatsApp)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Help Desk")
        .background(AppBackground())
        .onAppear {
            fetchSupportDetails()
        }
    }
    
    private func fetchSupportDetails() {
        guard let url = URL(string: APIConfig.baseURL + "support.php") else {
            isLoading = false
            return
        }
        Task {
            do {
                var request = URLRequest(url: url)
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                    await MainActor.run {
                        if let email = json["email"] { self.supportEmail = email }
                        if let whatsapp = json["whatsapp"] { self.supportWhatsApp = whatsapp }
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run { self.isLoading = false }
                }
            } catch {
                await MainActor.run { self.isLoading = false }
                print("Failed to fetch support details: \(error)")
            }
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.surfaceLight)
        .cornerRadius(12)
    }
}
