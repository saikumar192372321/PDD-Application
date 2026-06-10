//
//  ForgotPasswordView.swift
//  VSN Home
//
//  Created by SAIL on 06/01/26.
//


import SwiftUI

struct ForgotPasswordView: View {

    // STEP CONTROL
    @State private var step = 1   // 1 = Email, 2 = Reset Password

    // COMMON
    @State private var isLoading = false
    @State private var errorMessage = ""

    // STEP 1 – Email
    @State private var email = ""

    // STEP 2 – Passwords
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                Spacer()

                Text(step == 1 ? "Forgot Password" : "Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                if step == 1 {
                    emailView
                } else {
                    resetPasswordView
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: mainAction) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(step == 1 ? "Verify Email" : "Update Password")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(14)

                Spacer()
            }
            .padding(25)
        }
    }

    // MARK: - Step 1 UI
    var emailView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .foregroundColor(.white)

            TextField("Enter your registered email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Step 2 UI
    var resetPasswordView: some View {
        VStack(spacing: 15) {

            passwordField("New Password", text: $newPassword)
            passwordField("Confirm Password", text: $confirmPassword)
        }
    }

    func passwordField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.white)

            HStack {
                Group {
                    if showPassword {
                        TextField(title, text: text)
                    } else {
                        SecureField(title, text: text)
                    }
                }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Main Button Action
    func mainAction() {
        errorMessage = ""

        if step == 1 {
            verifyEmail()
        } else {
            resetPassword()
        }
    }

    // MARK: - Logic
    func verifyEmail() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        isLoading = true

        // 🔗 API CALL – Verify email exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            step = 2   // ✅ Move to password reset
        }
    }

    func resetPassword() {
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required"
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isLoading = true

        // 🔗 API CALL – Update password
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            print("Password updated for \(email)")
        }
    }
}
