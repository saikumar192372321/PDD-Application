import SwiftUI

struct AdminEnrollmentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var upiId = ""
    @State private var isLoading = false
    @State private var message = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("System Enrollment")
                            .font(.system(size: 24, weight: .black))
                        Text("Provisioning a new administrative access key.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 20) {
                        ConfigField(label: "Admin Email Identifier", icon: "envelope.fill", text: $email, prompt: "admin@vsn-home.in")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("SECURITY ACCESS KEY", systemImage: "key.fill")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(AppColors.secondary)
                            SecureField("Enter administrator password", text: $password)
                                .font(.system(size: 15, weight: .semibold))
                                .padding()
                                .background(AppColors.textPrimary.opacity(0.04))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
                        }
                        
                        ConfigField(label: "Business UPI ID (Optional)", icon: "indianrupeesign.circle.fill", text: $upiId, prompt: "business@upi")
                    }
                    .padding(24)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    
                    Button(action: enrollAdmin) {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("FINALIZE ENROLLMENT")
                                .font(.system(size: 14, weight: .black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(email.isEmpty || password.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(AppColors.primaryGradient))
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    
                    if !message.isEmpty {
                        Text(message)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(message.contains("success") ? .green : .red)
                    }
                }
                .padding(22)
            }
        }
        .navigationTitle("Personnel Provisioning")
    }
    
    private func enrollAdmin() {
        guard let url = URL(string: APIConfig.baseURL + "add_admin.php") else { return }
        isLoading = true
        message = ""
        
        let body = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "upi_id": upiId.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        Task {
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
                        message = "System Administrator successfully enrolled."
                        HapticManager.shared.notify(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
                    } else {
                        message = "Enrollment failed: \(response.message)"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    message = "Network connectivity failure."
                }
            }
        }
    }
}
