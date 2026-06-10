import SwiftUI

// MARK: - Sign Up View (Refined B2B Registration)
struct SignUpView: View {
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var referralCodeInput = ""
    @State private var address = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false

    // Touched flags – show error only after user interacts with a field
    @State private var nameTouched = false
    @State private var phoneTouched = false
    @State private var emailTouched = false
    @State private var passwordTouched = false
    @State private var addressTouched = false

    @Environment(\.dismiss) var dismiss

    // MARK: - Validation helpers
    private var nameError: String? {
        guard nameTouched else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return "Full name is required." }
        let regex = "^[A-Za-z ]+$"
        if trimmed.range(of: regex, options: .regularExpression) == nil {
            return "Name must contain alphabets only."
        }
        return nil
    }

    private var phoneError: String? {
        guard phoneTouched else { return nil }
        if phone.isEmpty { return "Mobile number is required." }
        let regex = "^[6-9][0-9]{9}$"
        if phone.range(of: regex, options: .regularExpression) == nil {
            return "Enter a valid 10-digit number starting with 6–9."
        }
        return nil
    }

    private var emailError: String? {
        guard emailTouched else { return nil }
        if email.isEmpty { return "Email address is required." }
        let allowed = ["@gmail.com", "@yahoo.com", "@saveetha.com", "@outlook.com"]
        let lower = email.lowercased()
        if !allowed.contains(where: { lower.hasSuffix($0) }) {
            return "Use a @gmail.com, @yahoo.com, @saveetha.com or @outlook.com address."
        }
        // Basic format check
        let emailRegex = "^[A-Za-z0-9._%+\\-]+@(gmail|yahoo|saveetha|outlook)\\.(com)$"
        if lower.range(of: emailRegex, options: .regularExpression) == nil {
            return "Please enter a valid email address."
        }
        return nil
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if password.isEmpty { return "Password is required." }
        if password.count < 8 { return "Password must be at least 8 characters." }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            return "Password must contain at least one uppercase letter."
        }
        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            return "Password must contain at least one lowercase letter."
        }
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return "Password must contain at least one number."
        }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) == nil {
            return "Password must contain at least one special character."
        }
        return nil
    }

    private var addressError: String? {
        guard addressTouched else { return nil }
        if address.trimmingCharacters(in: .whitespaces).isEmpty { return "Shop address is required." }
        return nil
    }

    private var isFormValid: Bool {
        nameError == nil && nameTouched &&
        phoneError == nil && phoneTouched &&
        emailError == nil && emailTouched &&
        passwordError == nil && passwordTouched &&
        addressError == nil && addressTouched
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {

                    // Header
                    VStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .shadow(color: AppColors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
                                } else {
                                    Image("AppLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .shadow(color: AppColors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
                                }
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(AppColors.primary)
                                    .clipShape(Circle())
                                    .offset(x: 5, y: 5)
                            }
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $selectedImage)
                        }
                        Text("Business Registration")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Create your wholesale partner account.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, 40)

                    // Input Form
                    VStack(spacing: 20) {

                        // Full Name
                        ValidatedSignUpField(
                            label: "Full Name",
                            icon: "person.fill",
                            text: $name,
                            errorMessage: nameError,
                            onEditingChanged: { nameTouched = true }
                        )

                        // Mobile Number
                        ValidatedSignUpField(
                            label: "Mobile Number",
                            icon: "phone.fill",
                            text: $phone,
                            keyboard: .phonePad,
                            errorMessage: phoneError,
                            onEditingChanged: { phoneTouched = true }
                        )

                        // Email
                        ValidatedSignUpField(
                            label: "Email Address",
                            icon: "envelope.fill",
                            text: $email,
                            keyboard: .emailAddress,
                            errorMessage: emailError,
                            onEditingChanged: { emailTouched = true }
                        )

                        // Referral Code (Optional)
                        ValidatedSignUpField(
                            label: "Referral Code (Optional)",
                            icon: "gift.fill",
                            text: $referralCodeInput,
                            onEditingChanged: { }
                        )

                        // Password
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)

                            HStack {
                                if showPassword {
                                    TextField("Enter Password", text: $password)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                } else {
                                    SecureField("Enter Password", text: $password)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                Button {
                                    HapticManager.shared.trigger(.light)
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textSecondary.opacity(0.5))
                                }
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemFill))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(passwordTouched && passwordError != nil ? Color.red : Color.clear, lineWidth: 1.2)
                            )

                            if let err = passwordError {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 11))
                                    Text(err)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            // Password strength hints
                            if passwordTouched && !password.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    PasswordHint(text: "At least 8 characters", met: password.count >= 8)
                                    PasswordHint(text: "One uppercase letter (A–Z)", met: password.range(of: "[A-Z]", options: .regularExpression) != nil)
                                    PasswordHint(text: "One lowercase letter (a–z)", met: password.range(of: "[a-z]", options: .regularExpression) != nil)
                                    PasswordHint(text: "One number (0–9)", met: password.range(of: "[0-9]", options: .regularExpression) != nil)
                                    PasswordHint(text: "One special character (!@#$…)", met: password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil)
                                }
                                .padding(.top, 4)
                                .animation(.easeInOut, value: password)
                            }
                        }

                        // Address
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Shop Address")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)

                            TextEditor(text: $address)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .font(.system(size: 14))
                                .padding(12)
                                .background(Color(UIColor.secondarySystemFill))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(addressTouched && addressError != nil ? Color.red : Color.clear, lineWidth: 1.2)
                                )
                                .onChange(of: address) { _ in addressTouched = true }

                            if let err = addressError {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 11))
                                    Text(err)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(24)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
                    .animation(.easeInOut(duration: 0.2), value: nameError ?? "" + (phoneError ?? "") + (emailError ?? "") + (passwordError ?? "") + (addressError ?? ""))

                    // CTAs
                    VStack(spacing: 20) {
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        }

                        Button(action: {
                            // Mark all fields as touched to surface errors
                            nameTouched = true
                            phoneTouched = true
                            emailTouched = true
                            passwordTouched = true
                            addressTouched = true

                            guard isFormValid else { return }
                            HapticManager.shared.trigger(.medium)
                            registerUser()
                        }) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("REGISTER ACCOUNT")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(isFormValid ? AppColors.primary : AppColors.primary.opacity(0.4))
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                        }
                        .disabled(isLoading)

                        Button("ALREADY REGISTERED? LOG IN") { dismiss() }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarBackButtonHidden()
    }

    private func registerUser() {
        errorMessage = ""; isLoading = true
        var userDetails: [String: String] = [
            "name": name,
            "email": email.lowercased(),
            "password": password,
            "phone": phone,
            "address": address,
            "referral_code": referralCodeInput
        ]
        
        if let image = selectedImage, let encoded = image.jpegData(compressionQuality: 0.5)?.base64EncodedString() {
            userDetails["profile_image"] = encoded
        }
        Task {
            do {
                guard let url = URL(string: APIConfig.register) else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Invalid API URL"
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30
                request.httpBody = try JSONSerialization.data(withJSONObject: userDetails)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Register Status: \(httpResponse.statusCode)")
                }
                if let rawResponse = String(data: data, encoding: .utf8) {
                    print("📡 Register Response: \(rawResponse)")
                }

                let decoder = JSONDecoder()
                let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
                await MainActor.run {
                    isLoading = false
                    if registerResponse.status == "success" {
                        UserDefaults.standard.set(email.lowercased(), forKey: "last_enrolled_email")
                        UserDefaults.standard.removeObject(forKey: "last_enrolled_password")
                        dismiss()
                    } else {
                        self.errorMessage = registerResponse.message
                    }
                }
            } catch {
                let diagnostics = (error as NSError).localizedDescription
                await MainActor.run {
                    isLoading = false
                    self.errorMessage = "Network Error: \(diagnostics)"
                }
                print("📡 Register error: \(error)")
            }
        }
    }
}

// MARK: - Password Hint Row
struct PasswordHint: View {
    let text: String
    let met: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundColor(met ? .green : Color(UIColor.tertiaryLabel))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(met ? .green : Color(UIColor.secondaryLabel))
        }
    }
}

// MARK: - Validated Sign Up Field
struct ValidatedSignUpField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var errorMessage: String?
    var onEditingChanged: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)

            TextField("", text: $text)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .padding(14)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(errorMessage != nil ? Color.red : Color.clear, lineWidth: 1.2)
                )
                .onChange(of: text) { _ in onEditingChanged?() }

            if let err = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Register Response
struct RegisterResponse: Codable {
    let status: String
    let message: String
}
