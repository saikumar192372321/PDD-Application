import SwiftUI
import Observation

struct LoginView: View {

    @Binding var isLoggedIn: Bool
    @Binding var isAdmin: Bool
    @Binding var userEmail: String

    @State private var email           = ""
    @State private var password        = ""
    @State private var showPassword    = false
    @State private var isLoading       = false
    @State private var errorMessage    = ""

    @State private var signup          = false
    @State private var forgot          = false
    @State private var showAdminLogin  = false

    // animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var formOpacity: Double = 0.0

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Brand Header ────────────────────────────────
                        VStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: AppColors.primary.opacity(0.15), radius: 20, x: 0, y: 8)
                                .scaleEffect(logoScale)

                            Text("VSN Home")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Wholesale B2B Platform")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                        // ── Form Card ───────────────────────────────────
                        VStack(spacing: 20) {
                            // Section header
                            HStack {
                                Text("Sign In")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                            }

                            // Email field
                            FieldRow(icon: "envelope.fill", iconColor: AppColors.primary) {
                                TextField("Email address", text: $email)
                                    .onChange(of: email) { email = $0.lowercased().trimmingCharacters(in: .whitespaces) }
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textPrimary)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }

                            // Password field
                            FieldRow(icon: "lock.fill", iconColor: AppColors.primary) {
                                Group {
                                    if showPassword {
                                        TextField("Enter Security Key", text: $password)
                                    } else {
                                        SecureField("Enter Security Key", text: $password)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textPrimary)
                                .overlay(alignment: .trailing) {
                                    Button {
                                        HapticManager.shared.trigger(.light)
                                        showPassword.toggle()
                                    } label: {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }

                            // Error message
                            if !errorMessage.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text(errorMessage)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(AppColors.error)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.error.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Sign In button
                            Button(action: {
                                HapticManager.shared.trigger(.medium)
                                loginUser()
                            }) {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                            .scaleEffect(0.85)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColors.primaryGradient)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: AppColors.primary.opacity(0.25), radius: 10, x: 0, y: 4)
                            }
                            .disabled(isLoading)

                            // Forgot password
                            Button("Forgot password?") {
                                HapticManager.shared.trigger(.light)
                                forgot = true
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.primary)
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 20)
                        .opacity(formOpacity)

                        // ── Footer links ────────────────────────────────
                        VStack(spacing: 16) {
                            // Sign up link
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                Button("Sign Up") {
                                    HapticManager.shared.trigger(.medium)
                                    signup = true
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                            }

                            // Admin access (subtle)
                            Button("Admin Access") {
                                HapticManager.shared.trigger(.light)
                                showAdminLogin = true
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary.opacity(0.55))
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                        .opacity(formOpacity)
                    }
                }
            }
            .navigationDestination(isPresented: $signup) { SignUpView() }
            .navigationDestination(isPresented: $forgot)  { ForgotPasswordView() }
            .fullScreenCover(isPresented: $showAdminLogin) {
                AdminLoginView(
                    isLoggedIn: $isLoggedIn,
                    productStore: GroceryProductStore(),
                    notificationStore: NotificationStore(),
                    onDismiss: { showAdminLogin = false }
                )
                .environmentObject(TabBarState())
            }
            .onAppear {
                // One-time convenience: if the user just registered,
                // pre-fill their email so they don't have to retype it.
                // The hint is consumed immediately and removed so subsequent
                // logins (including by a different new user) start clean.
                if let e = UserDefaults.standard.string(forKey: "last_enrolled_email") {
                    email = e
                    UserDefaults.standard.removeObject(forKey: "last_enrolled_email")
                    UserDefaults.standard.removeObject(forKey: "last_enrolled_password") // belt-and-suspenders cleanup
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { logoScale = 1.0 }
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) { formOpacity = 1.0 }
            }
        }
    }

    // MARK: - Auth logic (unchanged)
    private func loginUser() {
        // Force Server-Side Authentication
        errorMessage = ""; isLoading = true
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both Email and Password"
            isLoading = false
            return
        }
        
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL + "login.php") else { isLoading = false; return }
        let credentials = ["email": email.lowercased().trimmingCharacters(in: .whitespaces), "password": password]
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("close", forHTTPHeaderField: "Connection") // Prevents reuse of dead connections (-1005 error)
                request.timeoutInterval = 30
                request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Debugging help
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Login Status: \(httpResponse.statusCode)")
                }
                
                let decoder = JSONDecoder()
                let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                await MainActor.run {
                    isLoading = false
                    if loginResponse.status == "success", let user = loginResponse.data {
                        let emailToSave = user.email.lowercased().trimmingCharacters(in: .whitespaces)
                        SessionManager.shared.startSession(
                            email: emailToSave,
                            isAdmin: user.is_admin,
                            name: user.name ?? "",
                            phone: user.phone ?? "",
                            address: user.address ?? "",
                            businessName: user.business_name ?? "",
                            gstin: user.gstin ?? "",
                            coins: user.coins ?? 0,
                            referralCode: user.referral_code ?? "",
                            referredBy: user.referred_by ?? ""
                        )
                        self.userEmail = emailToSave
                        self.isAdmin = user.is_admin
                        self.isLoggedIn = true
                    } else {
                        self.errorMessage = loginResponse.message
                    }
                }
            } catch {
                await MainActor.run { isLoading = false; self.errorMessage = "Server offline – check connection" }
            }
        }
    }
}

// MARK: - Reusable field row wrapper
struct FieldRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 20)
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.primary.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Response models
struct LoginResponse: Codable {
    let status: String
    let message: String
    let data: UserDetails?
}

struct UserDetails: Codable {
    let email: String
    let name: String?
    let phone: String?
    let address: String?
    let business_name: String?
    let gstin: String?
    let profile_image: String?
    let coins: Int?
    let referral_code: String?
    let referred_by: String?
    let is_admin: Bool
}

#Preview {
    LoginView(isLoggedIn: .constant(false), isAdmin: .constant(false), userEmail: .constant(""))
}
