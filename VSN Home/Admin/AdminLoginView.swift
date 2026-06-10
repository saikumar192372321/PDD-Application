import SwiftUI

// MARK: - Admin Login View
struct AdminLoginView: View {
    
    @Binding var isLoggedIn: Bool
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    @Binding var selectedLanguage: AppLanguage
    var onDismiss: () -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var isAuthenticated = false
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var serverErrorMessage = ""
    
    var body: some View {
        if isAuthenticated {
            AdminTabView(
                productStore: productStore,
                notificationStore: notificationStore,
                selectedLanguage: $selectedLanguage,
                onLogout: {
                    isAuthenticated = false
                    try? KeychainManager.delete(key: "adminEmail")
                    try? KeychainManager.delete(key: "adminUPI")
                    onDismiss()
                }
            )
        } else {
            NavigationStack {
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    
                    // Decorative Background Elements
                    VStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 400, height: 400)
                            .blur(radius: 80)
                            .offset(x: -150, y: -200)
                        Spacer()
                        Circle()
                            .fill(AppColors.secondary.opacity(0.1))
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(x: 150, y: 150)
                    }
                    .ignoresSafeArea()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Button(action: { 
                                    HapticManager.shared.trigger(.light)
                                    onDismiss() 
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 44, height: 44)
                                        .background(AppColors.surface)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                
                                Spacer()
                                
                                Text("ADMIN PORTAL")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(AppColors.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppColors.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // Content
                            VStack(spacing: 40) {
                                // Security Badge Section
                                VStack(spacing: 24) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primary.opacity(0.05))
                                            .frame(width: 140, height: 140)
                                        
                                        Circle()
                                            .stroke(AppColors.primary.opacity(0.1), lineWidth: 1)
                                            .frame(width: 160, height: 160)
                                        
                                        Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 60))
                                            .foregroundStyle(AppColors.primaryGradient)
                                            .shadow(color: AppColors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                                    }
                                    .padding(.top, 20)
                                    
                                    VStack(spacing: 12) {
                                        Text("Systems Access")
                                            .font(.system(size: 34, weight: .black))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Text("AUTHORIZED PERSONNEL ONLY")
                                            .font(.system(size: 9, weight: .black))
                                            .tracking(2)
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.1))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.red.opacity(0.2), lineWidth: 1))
                                    }
                                }
                                
                                // Login Card
                                VStack(spacing: 24) {
                                    // Username Input
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label("ADMIN IDENTIFIER", systemImage: "person.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(AppColors.secondary)
                                            .padding(.leading, 4)
                                        
                                        HStack {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                                                .font(.system(size: 14))
                                            
                                            TextField("", text: $username, prompt: Text("sai1@vsn.com").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                                .foregroundColor(AppColors.textPrimary)
                                                .font(.system(size: 16, weight: .semibold))
                                                .keyboardType(.emailAddress)
                                                .autocorrectionDisabled()
                                                .textInputAutocapitalization(.never)
                                        }
                                        .padding()
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    // Password Input
                                    VStack(alignment: .leading, spacing: 12) {
                                        Label("SECURITY KEY", systemImage: "key.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(AppColors.secondary)
                                            .padding(.leading, 4)
                                        
                                        HStack {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(AppColors.textSecondary.opacity(0.4))
                                                .font(.system(size: 14))
                                            
                                            if showPassword {
                                                TextField("", text: $password, prompt: Text("••••••••").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                                    .autocorrectionDisabled()
                                                    .textInputAutocapitalization(.never)
                                            } else {
                                                SecureField("", text: $password, prompt: Text("••••••••").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                            }
                                        }
                                        .foregroundColor(AppColors.textPrimary)
                                        .font(.system(size: 16, weight: .semibold))
                                        .overlay(alignment: .trailing) {
                                            Button {
                                                HapticManager.shared.trigger(.light)
                                                showPassword.toggle()
                                            } label: {
                                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                            }
                                        }
                                        .padding()
                                        .background(AppColors.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    if showError {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                            Text(serverErrorMessage.isEmpty ? "ACCESS DENIED: INVALID CREDENTIALS" : serverErrorMessage.uppercased())
                                        }
                                        .foregroundColor(.red)
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                    
                                    // Action Buttons
                                    VStack(spacing: 24) {
                                        Button(action: {
                                            HapticManager.shared.trigger(.medium)
                                            isLoading = true
                                            
                                            Task {
                                                do {
                                                    guard let url = URL(string: APIConfig.baseURL + "admin_login.php") else { return }
                                                    var request = URLRequest(url: url)
                                                    request.httpMethod = "POST"
                                                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                                    request.addValue("close", forHTTPHeaderField: "Connection")
                                                    request.timeoutInterval = 30
                                                    
                                                    let body = ["email": username.trimmingCharacters(in: .whitespacesAndNewlines), "password": password]
                                                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                                                    
                                                    let (data, _) = try await URLSession.shared.data(for: request)
                                                    let response = try JSONDecoder().decode(AdminLoginResponse.self, from: data)
                                                    
                                                    await MainActor.run {
                                                        isLoading = false
                                                        if response.status == "success" {
                                                            HapticManager.shared.notify(.success)
                                                            
                                                            // PERSIST ADMIN DETAILS TO KEYCHAIN
                                                            try? KeychainManager.save(response.data?.email ?? username, key: "adminEmail")
                                                            if let upi = response.data?.upi_id {
                                                                try? KeychainManager.save(upi, key: "adminUPI")
                                                            }
                                                            
                                                            isAuthenticated = true
                                                            showError = false
                                                        } else {
                                                            HapticManager.shared.notify(.error)
                                                            serverErrorMessage = response.message
                                                            showError = true
                                                        }
                                                    }
                                                } catch {
                                                    await MainActor.run {
                                                        isLoading = false
                                                        serverErrorMessage = "Connection Error"
                                                        showError = true
                                                    }
                                                }
                                            }
                                        }) {
                                            HStack {
                                                if isLoading {
                                                    ProgressView()
                                                        .tint(.white)
                                                        .padding(.trailing, 8)
                                                }
                                                Text(isLoading ? "VERIFYING..." : "INITIATE SESSION")
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 18)
                                            .background(username.isEmpty || password.isEmpty ? AnyShapeStyle(AppColors.textSecondary.opacity(0.1)) : AnyShapeStyle(AppColors.primaryGradient))
                                            .foregroundColor(username.isEmpty || password.isEmpty ? AppColors.textSecondary.opacity(0.3) : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: (username.isEmpty || password.isEmpty) ? .clear : AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                                        }
                                        .disabled(username.isEmpty || password.isEmpty || isLoading)
                                        
                                        NavigationLink(destination: AdminForgotPasswordView()) {
                                            Text("Security Recovery Pathway")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AppColors.textSecondary)
                                                .opacity(0.7)
                                        }
                                    }
                                }
                                .padding(24)
                                .background(AppColors.surface.opacity(0.6))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 32))
                                .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
        }
    }
}
