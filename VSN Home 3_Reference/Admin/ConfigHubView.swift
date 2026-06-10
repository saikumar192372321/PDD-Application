import SwiftUI

struct ConfigHubView: View {
    @State private var email = ""
    @State private var whatsapp = ""
    @State private var deliveryCharge = "0"
    @State private var freeDeliveryThreshold = "5000"
    @State private var deliveryNote = ""
    @State private var masterKey = ""
    @State private var rzpKey = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var message = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Support Channels
                        VStack(alignment: .leading, spacing: 20) {
                            Text("B2B Support Channels")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Support Email", icon: "envelope.fill", text: $email, prompt: "support@vsn-home.in")
                            ConfigField(label: "WhatsApp Hub Number", icon: "message.fill", text: $whatsapp, prompt: "+91 9059270899")
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // 2. Logistics & Delivery
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Delivery & Logistics Protocol")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Flat Delivery Charge (₹)", icon: "truck.box.fill", text: $deliveryCharge, prompt: "0", keyboardType: .decimalPad)
                            ConfigField(label: "Free Delivery Above (₹)", icon: "sparkles", text: $freeDeliveryThreshold, prompt: "e.g. 5000", keyboardType: .numberPad)
                            ConfigField(label: "Logistics Delivery Note", icon: "note.text", text: $deliveryNote, prompt: "e.g. For 50kg bag")
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // 3. Security Configuration
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Master Security Pathway")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Administrative Master Key", icon: "key.fill", text: $masterKey, prompt: "Required for sensitive actions")
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // Payment Gateway Configuration
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Payment Gateway Configuration")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Razorpay Public Key", icon: "creditcard.fill", text: $rzpKey, prompt: "rzp_test_...")
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // 4. Admin Enrollment (Direct)
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Administrative Personnel Enrollment")
                                .font(.system(size: 16, weight: .bold))
                            
                            NavigationLink(destination: AdminEnrollmentView()) {
                                HStack {
                                    Image(systemName: "person.badge.plus.fill")
                                        .foregroundColor(AppColors.primary)
                                    Text("ENROLL NEW SYSTEM ADMINISTRATOR")
                                        .font(.system(size: 12, weight: .black))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding()
                                .background(AppColors.primary.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // Save Button
                        Button(action: saveSettings) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("UPDATE ECOSYSTEM CONFIG")
                                    .font(.system(size: 14, weight: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(AppColors.primaryGradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                    .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                        }
                        .disabled(isSaving)
                        .padding(.top, 20)
                        
                        if !message.isEmpty {
                            Text(message)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(message.contains("Success") ? .green : .red)
                        }
                    }
                    .padding(22)
                }
            }
        }
        .navigationTitle("Global Protocol")
        .onAppear { fetchSettings() }
    }
    
    private func fetchSettings() {
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.addValue("close", forHTTPHeaderField: "Connection")
                request.timeoutInterval = 30
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        self.email = json["email"] as? String ?? ""
                        self.whatsapp = json["whatsapp"] as? String ?? ""
                        self.deliveryCharge = json["delivery_charge"] as? String ?? "0"
                        self.freeDeliveryThreshold = json["free_delivery_threshold"] as? String ?? "5000"
                        self.deliveryNote = json["delivery_note"] as? String ?? ""
                        self.masterKey = json["admin_master_key"] as? String ?? ""
                        self.rzpKey = json["razorpay_key"] as? String ?? APIConfig.razorpayKeyID
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func saveSettings() {
        if masterKey.trimmingCharacters(in: .whitespaces).isEmpty {
            message = "Error: Master Key cannot be empty"
            return
        }
        
        guard let url = URL(string: APIConfig.baseURL + "support.php") else { return }
        isSaving = true
        message = ""
        
        let body = [
            "email": email,
            "whatsapp": whatsapp,
            "delivery_charge": deliveryCharge,
            "free_delivery_threshold": freeDeliveryThreshold,
            "delivery_note": deliveryNote,
            "admin_master_key": masterKey,
            "razorpay_key": rzpKey
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
                    isSaving = false
                    if response.status == "success" {
                        message = "Ecosystem Protocol Successfully Updated"
                        HapticManager.shared.notify(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                    } else {
                        message = "Update Failed: \(response.message)"
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    message = "Network connectivity failure"
                }
            }
        }
    }
}

struct ConfigField: View {
    let label: String
    let icon: String
    @Binding var text: String
    let prompt: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label.uppercased(), systemImage: icon)
                .font(.system(size: 9, weight: .black))
                .foregroundColor(AppColors.secondary)
            
            TextField(prompt, text: $text)
                .keyboardType(keyboardType)
                .font(.system(size: 15, weight: .semibold))
                .padding()
                .background(AppColors.textPrimary.opacity(0.04))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.textPrimary.opacity(0.1), lineWidth: 1))
        }
    }
}
