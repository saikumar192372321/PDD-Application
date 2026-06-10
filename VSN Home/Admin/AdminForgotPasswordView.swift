import SwiftUI

struct AdminForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var adminKey = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var stage: ResetStage = .identify
    @State private var isLoading = false
    @State private var message = ""
    @State private var showMasterKey = false
    
    enum ResetStage {
        case identify, verify, reRegister, success
    }
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Secure Icon
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: stage == .reRegister ? "person.badge.plus.fill" : "lock.shield.fill")
                        .font(.system(size: stage == .reRegister ? 40 : 50))
                        .foregroundStyle(AppColors.primaryGradient)
                        .glow(color: AppColors.primary, radius: 10)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text(stage == .success ? "ACCESS RESTORED" : (stage == .reRegister ? "ADMIN RE-REGISTRATION" : "SECURE RESET"))
                        .font(.system(size: 10, weight: .black))
                        .tracking(3)
                        .foregroundColor(AppColors.secondary)
                    
                    Text(subtitleForStage)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 24) {
                    if stage == .identify {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("ADMIN IDENTIFIER", systemImage: "envelope.fill")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.secondary)
                            
                            HStack {
                                TextField("", text: $email, prompt: Text("admin@vsn.com").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 14, weight: .bold))
                                    .textInputAutocapitalization(.never)
                            }
                            .padding()
                            .background(AppColors.textPrimary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                        }
                    } else if stage == .verify {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("MASTER KEY AUTHORIZATION", systemImage: "key.fill")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(AppColors.secondary)
                            
                            HStack {
                                if showMasterKey {
                                    TextField("", text: $adminKey, prompt: Text("ENTER MASTER KEY").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                } else {
                                    SecureField("", text: $adminKey, prompt: Text("••••••••").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                }
                                
                                Button(action: { showMasterKey.toggle() }) {
                                    Image(systemName: showMasterKey ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .font(.system(size: 14, weight: .bold))
                            .padding()
                            .background(AppColors.textPrimary.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                        }
                    } else if stage == .reRegister {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("NEW SECURITY KEY", systemImage: "lock.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(AppColors.secondary)
                                
                                SecureField("", text: $newPassword, prompt: Text("Enter New Password").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding()
                                    .background(AppColors.textPrimary.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Label("CONFIRM SECURITY KEY", systemImage: "lock.shield.fill")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(AppColors.secondary)
                                
                                SecureField("", text: $confirmPassword, prompt: Text("Confirm New Password").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding()
                                    .background(AppColors.textPrimary.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.success.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.success)
                                    .glow(color: AppColors.success, radius: 10)
                            }
                            
                            Text("Administrator re-registration complete. Use your new credentials for future sessions.")
                                .font(.subheadline.bold())
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    if !message.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(message.uppercased())
                        }
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(stage == .success ? AppColors.success : .red)
                    }
                    
                    Button(action: handleAction) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(buttonText)
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(1)
                                if stage != .success {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(stage == .success ? AnyShapeStyle(AppColors.success.gradient) : AnyShapeStyle(AppColors.primaryGradient))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .glow(color: stage == .success ? AppColors.success : AppColors.primary, radius: 10)
                    }
                    .padding(.top, 10)
                }
                .padding(32)
                .background(AppColors.textPrimary.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .overlay(RoundedRectangle(cornerRadius: 40).stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1))
                .padding(.horizontal, 25)
                
                if stage != .success {
                    Button(action: { dismiss() }) {
                        Text("RETURN TO LOGIN")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
        .atmosphericBackground()
    }
    
    private var subtitleForStage: String {
        switch stage {
        case .identify: return "Verify your administrator email to initiate the secure recovery process."
        case .verify: return "To proceed, please enter your unique Administrator Master Key for identity confirmation."
        case .reRegister: return "Create your new secure administrator credentials."
        case .success: return "Your request has been processed successfully. Security protocols are active."
        }
    }
    
    private var buttonText: String {
        switch stage {
        case .identify: return "VERIFY IDENTITY"
        case .verify: return "AUTHORIZE RESET"
        case .reRegister: return "COMPLETE REGISTRATION"
        case .success: return "CLOSE PORTAL"
        }
    }
    
    private func handleAction() {
        HapticManager.shared.trigger(.medium)
        
        if stage == .success {
            dismiss()
            return
        }
        
        isLoading = true
        message = ""
        
        Task {
            do {
                switch stage {
                case .identify:
                    // Just basic local check for format, then proceed
                    if email.contains("@") {
                        await MainActor.run { 
                            stage = .verify
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            message = "Invalid Administrator Identifier"
                            isLoading = false
                        }
                    }
                    
                case .verify:
                    // Fetch master key from server settings
                    guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let masterKey = json["admin_master_key"] as? String {
                        
                        await MainActor.run {
                            isLoading = false
                            if adminKey == masterKey {
                                stage = .reRegister
                            } else {
                                message = "Master Key Authorization Failed"
                                HapticManager.shared.notify(.error)
                            }
                        }
                    } else {
                        await MainActor.run {
                            message = "Security Protocol Offline"
                            isLoading = false
                        }
                    }
                    
                case .reRegister:
                    if newPassword.count >= 6 && newPassword == confirmPassword {
                        guard let url = URL(string: APIConfig.baseURL + "add_admin.php") else { return }
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        
                        let body = ["email": email, "password": newPassword]
                        request.httpBody = try JSONSerialization.data(withJSONObject: body)
                        
                        let (data, _) = try await URLSession.shared.data(for: request)
                        let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
                        
                        await MainActor.run {
                            isLoading = false
                            if response.status == "success" {
                                stage = .success
                                HapticManager.shared.notify(.success)
                            } else {
                                message = response.message
                                HapticManager.shared.notify(.error)
                            }
                        }
                    } else {
                        await MainActor.run {
                            isLoading = false
                            message = newPassword != confirmPassword ? "Passwords do not match" : "Password too short"
                            HapticManager.shared.notify(.error)
                        }
                    }
                case .success:
                    break
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    message = "Connection Error"
                    HapticManager.shared.notify(.error)
                }
            }
        }
    }
}

#Preview {
    AdminForgotPasswordView()
}
