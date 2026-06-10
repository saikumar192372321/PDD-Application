import SwiftUI
import Observation

struct LoginView: View {

    @Binding var isLoggedIn: Bool
    @Binding var isAdmin: Bool
    @Binding var userEmail: String
    @Binding var selectedLanguage: AppLanguage

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
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)
                                
                                Image("AppLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                                    .scaleEffect(logoScale)
                            }

                            VStack(spacing: 4) {
                                Text("V.S.N. HOME")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                                    .tracking(2)

                                Text("ELITE WHOLESALE NETWORK")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                                    .tracking(1)
                            }
                        }
                        .padding(.top, 70)
                        .padding(.bottom, 45)

                        // ── Form Card (Glassmorphic) ────────────────────
                        VStack(spacing: 24) {
                            HStack {
                                Text("Partner Authentication")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                            }

                            VStack(spacing: 16) {
                                FieldRow(icon: "envelope.fill", iconColor: AppColors.textSecondary) {
                                    TextField("Business Email", text: $email)
                                        .onChange(of: email) { email = $0.lowercased().trimmingCharacters(in: .whitespaces) }
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                .background(Color.black.opacity(0.04))
                                .cornerRadius(14)

                                FieldRow(icon: "lock.fill", iconColor: AppColors.textSecondary) {
                                    Group {
                                        if showPassword {
                                            TextField("Master Key", text: $password)
                                        } else {
                                            SecureField("Master Key", text: $password)
                                        }
                                    }
                                    .font(.system(size: 15, weight: .medium))
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
                                .background(Color.black.opacity(0.04))
                                .cornerRadius(14)
                            }

                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.vertical, 4)
                            }

                            Button(action: {
                                HapticManager.shared.trigger(.medium)
                                loginUser()
                            }) {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("AUTHORIZE ACCESS")
                                            .font(.system(size: 14, weight: .black))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(AppColors.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: AppColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                            }
                            .disabled(isLoading)

                            Button("Recover Credentials?") {
                                HapticManager.shared.trigger(.light)
                                forgot = true
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(28)
                        .glassMorphic()
                        .padding(.horizontal, 24)
                        .opacity(formOpacity)

                        // ── Footer links ────────────────────────────────
                        VStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Text("New Partner?")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                Button("Request Enrollment") {
                                    HapticManager.shared.trigger(.medium)
                                    signup = true
                                }
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(AppColors.primary)
                            }

                            Button("ADMINISTRATIVE GATEWAY") {
                                HapticManager.shared.trigger(.light)
                                showAdminLogin = true
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            .tracking(1)
                        }
                        .padding(.top, 35)
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
                    selectedLanguage: $selectedLanguage,
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
    LoginView(isLoggedIn: .constant(false), isAdmin: .constant(false), userEmail: .constant(""), selectedLanguage: .constant(.english))
}
