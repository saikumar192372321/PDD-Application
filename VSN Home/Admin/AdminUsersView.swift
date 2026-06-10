import SwiftUI

struct AdminUsersView: View {
    @ObservedObject var productStore: GroceryProductStore
    @State private var users: [AdminUserInfo] = []
    @State private var isLoading = false
    @State private var showDeleteConfirmation = false
    @State private var userToDelete: AdminUserInfo? = nil
    @State private var isDeleting = false
    @State private var searchText = ""
    
    var filteredUsers: [AdminUserInfo] {
        if searchText.isEmpty { return users }
        return users.filter { 
            ($0.name ?? "").lowercased().contains(searchText.lowercased()) ||
            ($0.email ?? "").lowercased().contains(searchText.lowercased()) ||
            ($0.business_name ?? "").lowercased().contains(searchText.lowercased())
        }
    }
    
    struct AdminUserInfo: Codable, Identifiable {
        let id: String
        let name: String?
        let email: String?
        let phone: String?
        let business_name: String?
        let gstin: String?
        let upi_id: String?
        let address: String?
        let coins: String? // Decoded as string because backend sends "0"
        let referral_code: String?
        let referred_by: String?
        let created_at: String?
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Spacing for safeAreaInset header
                        Color.clear.frame(height: 10)

                        if filteredUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(AppColors.primaryGradient.opacity(0.2))
                                Text(searchText.isEmpty ? "No partners registered yet" : "No matching partners")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredUsers) { user in
                                    NavigationLink(destination: AdminUserOrdersView(userEmail: user.email ?? "", userName: user.business_name ?? user.name ?? "Partner", productStore: productStore)) {
                                        UserPartnerRow(user: user, onDelete: {
                                            userToDelete = user
                                            showDeleteConfirmation = true
                                        })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 100)
                }
        }
        .navigationTitle("Business Ledger")
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PARTNER MANAGEMENT")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(AppColors.secondary)
                Text("Active Business Ecosystem")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    TextField("Search Partner, Email, or Shop", text: $searchText)
                        .font(.system(size: 14))
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(10)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppColors.background.opacity(0.8))
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Divider()
            }
        }
        .overlay {
            if isLoading {
                ProgressView().tint(AppColors.primary)
            }
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView().tint(.white)
                        Text("Decommissioning Account...")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(BlurView(style: .systemThinMaterialDark))
                    .cornerRadius(20)
                }
            }
        }
        .onAppear { fetchUsers() }
        .refreshable { fetchUsers() }
        .alert("Remove Partner?", isPresented: $showDeleteConfirmation, presenting: userToDelete) { user in
            Button("Cancel", role: .cancel) {}
            Button("Delete Account", role: .destructive) {
                deleteUser(email: user.email ?? "")
            }
        } message: { user in
            Text("Are you sure you want to delete \(user.name ?? "this partner")'s business account? This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SignUpView()) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("ENROLL")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private func deleteUser(email: String) {
        guard let url = URL(string: APIConfig.baseURL + "delete_account.php") else { return }
        isDeleting = true
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
                
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
                
                await MainActor.run {
                    isDeleting = false
                    if response.status == "success" {
                        withAnimation {
                            self.users.removeAll { $0.email == email }
                        }
                        HapticManager.shared.notify(.success)
                    }
                }
            } catch {
                await MainActor.run { isDeleting = false }
                print("Deletion failed: \(error)")
            }
        }
    }
    
    private func fetchUsers() {
        isLoading = true
        guard let url = URL(string: APIConfig.baseURL + "get_users.php") else { return }
        
        Task {
            do {
                var request = URLRequest(url: url)
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(APIResponse<[FailableDecodable<AdminUserInfo>]>.self, from: data)
                await MainActor.run {
                    if response.status == "success" {
                        self.users = (response.data ?? []).compactMap { $0.base }
                    }
                    isLoading = false
                }
            } catch {
                print("Failed to fetch users: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct UserPartnerRow: View {
    let user: AdminUsersView.AdminUserInfo
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text((user.business_name ?? "BUSINESS").uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(user.name ?? "Unknown Partner")
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                
                Button(action: { onDelete() }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label(user.email ?? "No Email", systemImage: "envelope.fill")
                Label(user.phone ?? "No Phone", systemImage: "phone.fill")
                Label("GSTIN: \(user.gstin ?? "N/A")", systemImage: "doc.text.fill")
                
                HStack(spacing: 12) {
                    Label("Coins: \(user.coins ?? "0")", systemImage: "coloncurrencysign.circle.fill")
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                    
                    if let code = user.referral_code {
                        Label("Code: \(code)", systemImage: "gift.fill")
                            .foregroundColor(.pink)
                    }
                }
                
                if let refBy = user.referred_by, !refBy.isEmpty {
                    Label("Referred by: \(refBy)", systemImage: "arrow.turn.down.right")
                        .italic()
                }

                if let upi = user.upi_id, !upi.isEmpty {
                    Label("UPI: \(upi)", systemImage: "indianrupeesign.circle.fill")
                }
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                    Text("PASSCODE: ENCRYPTED & SECURE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(AppColors.success)
                }
                .padding(.top, 4)
            }
            .font(.system(size: 12))
            .foregroundColor(AppColors.textSecondary)
            
            Text(user.address ?? "No Address Provided")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                .lineLimit(2)
        }
        .padding(20)
        .background(AppColors.surfaceLight)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Admin User Orders View
struct AdminUserOrdersView: View {
    let userEmail: String
    let userName: String
    @ObservedObject var productStore: GroceryProductStore
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isGenerating: Bool = false
    
    var userOrders: [Order] {
        productStore.orders.filter { $0.userEmail.lowercased() == userEmail.lowercased() }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if userOrders.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(AppColors.primaryGradient.opacity(0.2))
                            Text("No orders from this partner")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(userOrders) { order in
                                OrderRow(order: order, productStore: productStore, showShareSheet: $showShareSheet, shareURL: $shareURL, isGenerating: $isGenerating)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ActivityView(activityItems: [url])
            }
        }
        .navigationTitle("\(userName)'s Orders")
        .navigationBarTitleDisplayMode(.inline)
    }
}
