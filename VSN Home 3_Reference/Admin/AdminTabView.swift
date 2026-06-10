import SwiftUI

// MARK: - Admin Tab View
struct AdminTabView: View {
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    var onLogout: () -> Void
    
    @State private var selectedTab: AdminTab = .insights
    @StateObject private var tabBarState = TabBarState() // Controls custom bottom bar visibility
    @Namespace private var tabNamespace // For liquid highlight animation
    
    enum AdminTab: Int, CaseIterable {
        case insights, inventory, orders, partners, broadcast, profile
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            
            if !tabBarState.isHidden {
                liquidTabBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(tabBarState)
        .background(AppBackground())
        .accentColor(AppColors.primary)
    }
    
    private var tabContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AdminDashboardView(productStore: productStore)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.insights)
            
            NavigationStack {
                ProductListView(productStore: productStore)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.inventory)
            
            NavigationStack {
                AdminOrdersView(productStore: productStore)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.orders)

            NavigationStack {
                AdminUsersView(productStore: productStore)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.partners)
            
            NavigationStack {
                AdminNotificationView(notificationStore: notificationStore)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.broadcast)
            
            NavigationStack {
                AdminProfileView(onLogout: onLogout)
            }
            .environmentObject(tabBarState)
            .tag(AdminTab.profile)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 120)
        }
    }
    
    private var liquidTabBar: some View {
        ZStack {
            // Shared Liquid Highlight (Hyper-Glassy Bubble)
            Capsule()
                .fill(.ultraThickMaterial)
                .frame(width: 72, height: 42)
                .matchedGeometryEffect(id: "admin_bubble", in: tabNamespace, isSource: false)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .overlay {
                    Capsule()
                        .stroke(AppColors.primary.opacity(0.15), lineWidth: 0.5)
                }
                .padding(.horizontal, 8)
            
            HStack(spacing: 0) {
                AdminTabButton(tab: .insights, icon: "chart.bar.xaxis", label: "Insights", selectedTab: $selectedTab, namespace: tabNamespace)
                AdminTabButton(tab: .inventory, icon: "archivebox.fill", label: "Stock", selectedTab: $selectedTab, namespace: tabNamespace)
                AdminTabButton(tab: .orders, icon: "shippingbox.fill", label: "Orders", selectedTab: $selectedTab, namespace: tabNamespace)
                AdminTabButton(tab: .partners, icon: "person.2.fill", label: "Partners", selectedTab: $selectedTab, namespace: tabNamespace)
                AdminTabButton(tab: .broadcast, icon: "bell.badge.fill", label: "Alerts", selectedTab: $selectedTab, namespace: tabNamespace)
                AdminTabButton(tab: .profile, icon: "person.fill", label: "Self", selectedTab: $selectedTab, namespace: tabNamespace)
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
}

struct AdminTabButton: View {
    let tab: AdminTabView.AdminTab
    let icon: String
    let label: String
    @Binding var selectedTab: AdminTabView.AdminTab
    var namespace: Namespace.ID
    
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
                        .matchedGeometryEffect(id: "admin_bubble", in: namespace, isSource: isSelected)

                    Image(systemName: icon)
                        .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? AppColors.primary : .secondary.opacity(0.6))
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                
                Text(label)
                    .font(.system(size: 8, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? AppColors.primary : .secondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
        }
    }
}


// MARK: - Admin Profile View
struct AdminProfileView: View {
    var onLogout: () -> Void
    
    @State private var newAdminID = ""
    @State private var newAdminKey = ""
    @State private var newAdminUPI = ""
    @State private var showSuccess = false
    
    @State private var merchantUPIID = ""
    @State private var supportEmail = ""
    @State private var supportWhatsApp = ""
    @State private var deliveryRadius: Double = 25
    @State private var hubLatitude = ""
    @State private var hubLongitude = ""
    
    @State private var showSupportSuccess = false
    @State private var isUpdatingLogistics = false
    @State private var adminMasterKey = ""
    @State private var showMasterKeyToggle = false
    
    @State private var isEnrolling = false
    @State private var enrollmentError: String? = nil
    
    @State private var personalUPIID: String = ""
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // Header
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 90, height: 90)
                            Image(systemName: "person.badge.shield.checkmark.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("System Administrator")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("VSN Home — Admin Portal")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // System Info
                    VStack(spacing: 1) {
                        AdminInfoRow(title: "Admin ID", value: UserDefaults.standard.string(forKey: "adminUsername") ?? "sai@vsn.com", icon: "person.fill", color: AppColors.primary)
                        AdminInfoRow(title: "Role", value: "Super Admin", icon: "shield.checkered", color: .purple)
                        if let myUPI = UserDefaults.standard.string(forKey: "adminUPI"), !myUPI.isEmpty {
                            AdminInfoRow(title: "Personal UPI", value: myUPI, icon: "indianrupeesign.circle.fill", color: .orange)
                        }
                        AdminInfoRow(title: "App Version", value: "v2.5.0", icon: "info.circle.fill", color: AppColors.textSecondary)
                    }
                    .background(AppColors.surfaceLight)
                    .cornerRadius(16)
                    .padding(.horizontal, 22)
                    
                    // Add Admin
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enroll New Admin")
                            .font(.system(size: 16, weight: .bold))
                        
                        VStack(spacing: 14) {
                            AdminInputField(label: "Admin Email / ID", text: $newAdminID, icon: "person.badge.plus")
                            AdminInputField(label: "Password", text: $newAdminKey, icon: "key.fill", isSecure: true)
                            AdminInputField(label: "UPI ID (Optional)", text: $newAdminUPI, icon: "indianrupeesign.circle.fill")
                            
                            Button(action: {
                                HapticManager.shared.notify(.success)
                                enrollNewAdmin()
                            }) {
                                if isEnrolling {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Add Admin")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(buttonDisabled ? Color.gray.opacity(0.15) : AppColors.primary)
                            .foregroundColor(buttonDisabled ? AppColors.textSecondary : .white)
                            .cornerRadius(12)
                            .disabled(buttonDisabled || isEnrolling)
                            
                            if let error = enrollmentError {
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                            
                            if showSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppColors.success)
                                    Text("Admin enrolled successfully.")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.success)
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Payment Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "qrcode")
                                .foregroundColor(.orange)
                            Text("Payment Configuration")
                                .font(.system(size: 16, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MERCHANT UPI ID")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppColors.textSecondary)
                            HStack(spacing: 12) {
                                Image(systemName: "indianrupeesign.circle.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                TextField("yourname@upi", text: $merchantUPIID)
                                    .font(.system(size: 14, weight: .semibold))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemFill))
                            .cornerRadius(10)
                            
                            Text("This UPI ID will be pre-filled when customers pay via PhonePe, GPay, Paytm etc.")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Button(action: {
                            HapticManager.shared.notify(.success)
                            updateLogisticsDetails()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Save UPI ID")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(merchantUPIID.contains("@") ? Color.orange : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!merchantUPIID.contains("@"))
                        
                        if showSupportSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(AppColors.success)
                                Text("Settings updated.")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.success)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Master Key Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "key.viewfinder")
                                .foregroundColor(.red)
                            Text("Security: System Master Key")
                                .font(.system(size: 16, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ADMIN MASTER KEY")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppColors.textSecondary)
                            HStack(spacing: 12) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                
                                if showMasterKeyToggle {
                                    TextField("Enter New Master Key", text: $adminMasterKey)
                                        .font(.system(size: 14, weight: .semibold))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Enter New Master Key", text: $adminMasterKey)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                
                                Button(action: { showMasterKeyToggle.toggle() }) {
                                    Image(systemName: showMasterKeyToggle ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemFill))
                            .cornerRadius(10)
                            
                            Text("CRITICAL: This key is used to reset admin passwords. Keep it safe.")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        
                        Button(action: {
                            HapticManager.shared.notify(.success)
                            updateLogisticsDetails()
                        }) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                Text("Update Master Key")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(adminMasterKey.count >= 4 ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(adminMasterKey.count < 4)
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Logistics & Radius
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Update Logistics & Radius")
                            .font(.system(size: 16, weight: .bold))
                        
                        VStack(spacing: 16) {
                            HStack {
                                Label("Delivery Radius (KM)", systemImage: "map.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Spacer()
                                Text("\(Int(deliveryRadius)) KM")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(AppColors.primary)
                            }
                            
                            Slider(value: $deliveryRadius, in: 1...200, step: 1)
                                .tint(AppColors.primary)
                            
                            HStack(spacing: 14) {
                                AdminInputField(label: "Hub Latitude", text: $hubLatitude, icon: "location.fill")
                                AdminInputField(label: "Hub Longitude", text: $hubLongitude, icon: "location.north.fill")
                            }
                            
                            Button(action: {
                                HapticManager.shared.notify(.success)
                                updateLogisticsDetails()
                            }) {
                                if isUpdatingLogistics {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save Logistics Config")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isUpdatingLogistics)
                            
                            if showSupportSuccess {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(AppColors.success)
                                    Text("Logistics saved successfully.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColors.success)
                                }
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Logout
                    Button(action: {
                        HapticManager.shared.notify(.warning)
                        onLogout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(14)
                        .shadow(color: Color.red.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Admin Profile")
        .onAppear {
            fetchSupportDetails()
        }
    }
    
    private var buttonDisabled: Bool {
        newAdminID.isEmpty || newAdminKey.isEmpty || !newAdminID.contains("@")
    }

    private func enrollNewAdmin() {
        guard let url = URL(string: APIConfig.baseURL + "add_admin.php") else { return }
        isEnrolling = true
        enrollmentError = nil
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let body = ["email": newAdminID, "password": newAdminKey, "upi_id": newAdminUPI]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    await MainActor.run {
                        isEnrolling = false
                        enrollmentError = "Server Error: \(httpResponse.statusCode)"
                    }
                    return
                }

                do {
                    let apiResponse = try JSONDecoder().decode(SimpleResponse.self, from: data)
                    await MainActor.run {
                        isEnrolling = false
                        if apiResponse.status == "success" {
                            withAnimation { showSuccess = true; newAdminID = ""; newAdminKey = ""; newAdminUPI = "" }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { showSuccess = false }
                            }
                        } else {
                            enrollmentError = apiResponse.message
                        }
                    }
                } catch {
                    await MainActor.run {
                        isEnrolling = false
                        enrollmentError = "Malformed response from server."
                        if let body = String(data: data, encoding: .utf8) {
                            print("Server returned non-JSON: \(body)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isEnrolling = false
                    enrollmentError = "Connection failed. Check Server/IP."
                    print("Network error: \(error)")
                }
            }
        }
    }
    
    private func fetchSupportDetails() {
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        self.merchantUPIID = "\(json["upi_id"] ?? "")"
                        self.supportEmail = "\(json["email"] ?? "")"
                        self.supportWhatsApp = "\(json["whatsapp"] ?? "")"
                        
                        let radiusStr = "\(json["delivery_radius"] ?? "25")"
                        self.deliveryRadius = Double(radiusStr) ?? 25
                        
                        self.hubLatitude = "\(json["hub_latitude"] ?? "21.1458")"
                        self.hubLongitude = "\(json["hub_longitude"] ?? "79.0882")"
                        self.adminMasterKey = "\(json["admin_master_key"] ?? "sai@141")"
                    }
                }
            } catch {
                print("Failed to fetch support details: \(error)")
            }
        }
    }
    
    private func updateLogisticsDetails() {
        isUpdatingLogistics = true
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let bodyParams = [
                    "upi_id": merchantUPIID,
                    "email": supportEmail,
                    "whatsapp": supportWhatsApp,
                    "delivery_radius": "\(Int(deliveryRadius))",
                    "hub_latitude": hubLatitude,
                    "hub_longitude": hubLongitude,
                    "admin_master_key": adminMasterKey
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyParams)
                
                let (_, _) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    isUpdatingLogistics = false
                    withAnimation { showSupportSuccess = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSupportSuccess = false }
                    }
                }
            } catch {
                await MainActor.run {
                    isUpdatingLogistics = false
                    print("Failed to update logistics details: \(error)")
                }
            }
        }
    }
}

// MARK: - Sub-components
private struct AdminInfoRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
        .background(AppColors.surfaceLight)
    }
}

private struct AdminInputField: View {
    let label: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundColor(AppColors.primary).frame(width: 20)
                if isSecure {
                    SecureField("", text: $text).font(.system(size: 14, weight: .medium))
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 14, weight: .medium))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemFill))
            .cornerRadius(10)
        }
    }
}
