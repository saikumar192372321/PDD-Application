//
//  ForgotPasswordView.swift
//  VSN Home
//
//  Created by SAIL on 06/01/26.
//


import SwiftUI

struct ForgotPasswordView: View {
    
    @Environment(\.dismiss) var dismiss

    // STEP CONTROL
    @State private var step = 1   // 1 = Email, 3 = Reset Password (OTP skipped)

    // COMMON
    @State private var isLoading = false
    @State private var errorMessage = ""

    // STEP 1 – Email
    @State private var email = ""

    // OTP removed as requested

    // STEP 2 – Passwords
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    // removed login state variable

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 40) {
                    // Header Matrix
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: step == 1 ? "lock.shield.fill" : "key.radiowaves.forward.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.primaryGradient)
                                .glow(color: AppColors.primary, radius: 10)
                        }
                        
                        Text(step == 1 ? "FORGOT PASSWORD" : "RESET PASSWORD")
                            .font(.system(size: 10, weight: .black))
                            .tracking(3)
                            .foregroundColor(AppColors.secondary)
                        
                        Text(step == 1 ? "Verify Your Email" : "Create New Password")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 24) {
                        if step == 1 {
                            emailView
                        } else {
                            resetPasswordView
                        }
                        
                        if !errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMessage)
                            }
                            .foregroundColor(.red)
                            .font(.system(size: 11, weight: .bold))
                            .padding(.vertical, 8)
                        }
                        
                        Button(action: mainAction) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == 1 ? "CONTINUE" : "UPDATE PASSWORD")
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(AppColors.primaryGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(32)
                    .background(AppColors.textPrimary.opacity(0.02))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1))
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .atmosphericBackground()
        }
    }

    // MARK: - Step 1 UI
    var emailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("EMAIL ADDRESS", systemImage: "envelope.fill")
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(AppColors.secondary)

            TextField("", text: $email, prompt: Text("account@vsn.com").foregroundColor(AppColors.textSecondary.opacity(0.3)))
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .padding()
                .background(AppColors.textPrimary.opacity(0.03))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Step 2 UI
    var resetPasswordView: some View {
        VStack(spacing: 20) {
            passwordField("NEW PASSWORD", text: $newPassword, icon: "lock.fill")
            
            // Password strength hints
            if !newPassword.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    PasswordHint(text: "At least 8 characters", met: newPassword.count >= 8)
                    PasswordHint(text: "One uppercase letter (A–Z)", met: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                    PasswordHint(text: "One lowercase letter (a–z)", met: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                    PasswordHint(text: "One number (0–9)", met: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)
                    PasswordHint(text: "One special character (!@#$…)", met: newPassword.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil)
                }
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
            
            passwordField("CONFIRM PASSWORD", text: $confirmPassword, icon: "checkmark.shield.fill")
        }
        .animation(.default, value: newPassword)
    }

    // otpView removed

    func passwordField(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundColor(AppColors.secondary)

            HStack {
                Group {
                    if showPassword {
                        TextField("", text: text)
                    } else {
                        SecureField("", text: text)
                    }
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary.opacity(0.3))
                }
            }
            .padding()
            .background(AppColors.textPrimary.opacity(0.03))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.textPrimary.opacity(0.08), lineWidth: 1))
        }
    }

    // MARK: - Main Button Action
    func mainAction() {
        errorMessage = ""
        
        if step == 1 {
            Task { await verifyEmail() }
        } else {
            Task { await resetPassword() }
        }
    }

    // MARK: - Logic
    func verifyEmail() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard ValidationHelper.isValidEmail(email) else {
            errorMessage = "Invalid email format"
            return
        }

        isLoading = true
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL + "forgot_password.php") else { return }
        
        let body = ["email": email]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
            
            await MainActor.run {
                isLoading = false
                if response.status == "success" {
                    step = 3   // ✅ Directly to Reset Password
                } else {
                    errorMessage = response.message
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Connection error: \(error.localizedDescription)"
            }
        }
    }

    // verifyOTP removed

    func resetPassword() async {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        if let passError = ValidationHelper.getPasswordError(newPassword) {
            errorMessage = passError
            return
        }
        
        isLoading = true
        let baseURL = APIConfig.baseURL
        guard let url = URL(string: baseURL + "reset_password.php") else { return }
        
        let body = ["email": email, "password": newPassword]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SimpleResponse.self, from: data)
            
            await MainActor.run {
                isLoading = false
                if response.status == "success" {
                    print("Password updated for \(email)")
                    
                    // Update local cache to match new password
                    if let savedEmail = UserDefaults.standard.string(forKey: "last_enrolled_email"),
                       savedEmail.lowercased() == email.lowercased() {
                        UserDefaults.standard.set(newPassword, forKey: "last_enrolled_password")
                    }
                    
                    dismiss() // Go back to login
                } else {
                    errorMessage = response.message
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Update failed: \(error.localizedDescription)"
            }
        }
    }
}
