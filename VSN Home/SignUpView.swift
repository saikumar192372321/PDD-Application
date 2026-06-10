//
//  SignUpView.swift
//  VSN Home
//
//  Created by SAIL on 06/01/26.
//


import SwiftUI
import PhotosUI

struct SignUpView: View {

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var password = ""
    @State private var address = ""

    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    // Image Picker
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    // Profile Image Picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ZStack {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 110, height: 110)
                        .background(Color.white)
                        .clipShape(Circle())
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }

                    // Input Fields
                    inputField("Full Name", text: $name)
                    inputField("Phone Number", text: $phone, keyboard: .phonePad)
                    inputField("Email", text: $email, keyboard: .emailAddress)

                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .foregroundColor(.white)

                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                } else {
                                    SecureField("Enter password", text: $password)
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

                    // Address
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Address")
                            .foregroundColor(.white)

                        TextEditor(text: $address)
                            .frame(height: 90)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // Sign Up Button
                    Button(action: registerUser) {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Sign Up")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.85))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .disabled(isLoading)

                    // Back to Login
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.8))

                        NavigationLink("Login", destination: LoginView())
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .font(.footnote)
                }
                .padding(25)
            }
        }
    }

    // MARK: - Reusable Input Field
    func inputField(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.white)

            TextField(title, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Register Function
    func registerUser() {
        guard !name.isEmpty,
              !phone.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !address.isEmpty else {
            errorMessage = "All fields are required"
            return
        }

        errorMessage = ""
        isLoading = true

        // 🔗 API integration placeholder
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            print("User Registered")
        }
    }
}
