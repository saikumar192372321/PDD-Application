import SwiftUI

// MARK: - Admin Login View
struct AdminLoginView: View {
    
    @Binding var isLoggedIn: Bool
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
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
                onLogout: {
                    isAuthenticated = false
                    UserDefaults.standard.removeObject(forKey: "adminUsername")
                    UserDefaults.standard.removeObject(forKey: "adminUPI")
                    onDismiss()
                }
            )
        } else {
            NavigationStack {
                ZStack {
                    AppBackground()
                    
                    VStack(spacing: 30) {
                        HStack {
                            Button(action: { 
                                HapticManager.shared.trigger(.light)
                                onDismiss() 
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(12)
                                    .background(AppColors.textPrimary.opacity(0.04))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                            }
                            Spacer()
                            Text("ADMIN PORTAL")
                                .font(.system(size: 10, weight: .black))
                                .tracking(3)
                                .foregroundColor(AppColors.secondary)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Security Badge
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                    .glow(color: AppColors.primary, radius: 10)
                                
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(AppColors.primaryGradient)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Systems Access")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("AUTHORIZED PERSONNEL ONLY")
                                    .font(.system(size: 8, weight: .black))
                                    .tracking(2)
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        VStack(spacing: 24) {
                             // Username Input
                            VStack(alignment: .leading, spacing: 10) {
                                Label("ADMIN IDENTIFIER", systemImage: "person.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(AppColors.secondary)
                                
                                HStack {
                                    TextField("", text: $username, prompt: Text("sai@vsn.com").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                        .foregroundColor(AppColors.textPrimary)
                                        .font(.system(size: 14, weight: .bold))
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(AppColors.textPrimary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                            }
                            
                            // Password Input
                            VStack(alignment: .leading, spacing: 10) {
                                Label("SECURITY KEY", systemImage: "key.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(AppColors.secondary)
                                
                                HStack {
                                    if showPassword {
                                        TextField("", text: $password, prompt: Text("••••••••").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                    } else {
                                        SecureField("", text: $password, prompt: Text("••••••••").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                    }
                                }
                                .foregroundColor(AppColors.textPrimary)
                                .font(.system(size: 14, weight: .bold))
                                .overlay(alignment: .trailing) {
                                    Button {
                                        HapticManager.shared.trigger(.light)
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                    }
                                }
                                .padding()
                                .background(AppColors.textPrimary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                            }
                            
                            if showError {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.shield.fill")
                                    Text(serverErrorMessage.isEmpty ? "ACCESS DENIED: INVALID CREDENTIALS" : serverErrorMessage.uppercased())
                                }
                                .foregroundColor(.red)
                                .font(.system(size: 10, weight: .black))
                                .padding(.top, 4)
                            }
                            
                            // Action Buttons
                            VStack(spacing: 20) {
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
                                                    
                                                    // PERSIST ADMIN DETAILS
                                                    UserDefaults.standard.set(response.data?.email ?? username, forKey: "adminUsername")
                                                    if let upi = response.data?.upi_id {
                                                        UserDefaults.standard.set(upi, forKey: "adminUPI")
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
                                    Text("INITIATE SESSION")
                                        .font(.system(size: 14, weight: .black))
                                        .tracking(1)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(username.isEmpty || password.isEmpty ? AnyShapeStyle(AppColors.textPrimary.opacity(0.05)) : AnyShapeStyle(AppColors.primaryGradient))
                                        .foregroundColor(username.isEmpty || password.isEmpty ? AppColors.textSecondary.opacity(0.2) : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .glow(color: (username.isEmpty || password.isEmpty) ? .clear : AppColors.primary, radius: 10)
                                }
                                .disabled(username.isEmpty || password.isEmpty)
                                
                                NavigationLink(destination: AdminForgotPasswordView()) {
                                    Text("Security Recovery Pathway")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.6))
                                }
                            }
                        }
                        .padding(32)
                        .background(AppColors.textPrimary.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .overlay(RoundedRectangle(cornerRadius: 40).stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 25)
                }
                .atmosphericBackground()
            }
        }
    }
}
