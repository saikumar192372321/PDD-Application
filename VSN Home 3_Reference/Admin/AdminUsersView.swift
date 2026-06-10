import SwiftUI

struct AdminUsersView: View {
    @ObservedObject var productStore: GroceryProductStore
    @State private var users: [AdminUserInfo] = []
    @State private var isLoading = false
    @State private var showDeleteConfirmation = false
    @State private var userToDelete: AdminUserInfo? = nil
    @State private var isDeleting = false
    
    struct AdminUserInfo: Codable, Identifiable {
        let id: String
        let name: String
        let email: String
        let phone: String
        let business_name: String
        let gstin: String
        let upi_id: String?
        let address: String
        let coins: Int?
        let referral_code: String?
        let referred_by: String?
        let created_at: String
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            if isLoading {
                ProgressView().tint(AppColors.primary)
            } else if users.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.slash.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppColors.textSecondary.opacity(0.3))
                    Text("No registered partners found.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(users) { user in
                            UserPartnerRow(user: user, onDelete: {
                                userToDelete = user
                                showDeleteConfirmation = true
                            })
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        userToDelete = user
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(20)
                }
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
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(AppColors.background)
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
                deleteUser(email: user.email)
            }
        } message: { user in
            Text("Are you sure you want to delete \(user.name)'s business account? This action cannot be undone.")
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
                let response = try JSONDecoder().decode(APIResponse<[AdminUserInfo]>.self, from: data)
                await MainActor.run {
                    if response.status == "success" {
                        self.users = response.data
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
                    Text(user.business_name.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(AppColors.primary)
                    Text(user.name)
                        .font(.system(size: 16, weight: .bold))
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
                Label(user.email, systemImage: "envelope.fill")
                Label(user.phone, systemImage: "phone.fill")
                Label("GSTIN: \(user.gstin)", systemImage: "doc.text.fill")
                
                HStack(spacing: 12) {
                    Label("Coins: \(user.coins ?? 0)", systemImage: "coloncurrencysign.circle.fill")
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
            
            Text(user.address)
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
