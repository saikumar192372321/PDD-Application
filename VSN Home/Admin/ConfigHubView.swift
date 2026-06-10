import SwiftUI

struct ConfigHubView: View {
    @State private var email = ""
    @State private var whatsapp = ""
    @State private var deliveryCharge = "0"
    @State private var minOrderValue = "1000"
    @State private var freeDeliveryThreshold = "5000"
    @State private var referralReward = "50"
    @State private var deliveryNote = ""
    @State private var deliveryRadius = "25"
    @State private var hubLatitude = "21.1458"
    @State private var hubLongitude = "79.0882"
    @State private var masterKey = ""
    @State private var rzpKey = ""
    @State private var rzpSecret = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var message = ""
    @State private var showStatusAlert = false
    
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
                            ConfigField(label: "Minimum Order Value (₹)", icon: "cart.fill.badge.plus", text: $minOrderValue, prompt: "1000", keyboardType: .numberPad)
                            ConfigField(label: "Free Delivery Above (₹)", icon: "sparkles", text: $freeDeliveryThreshold, prompt: "e.g. 5000", keyboardType: .numberPad)
                            ConfigField(label: "Referral Reward (Coins)", icon: "gift.fill", text: $referralReward, prompt: "50", keyboardType: .numberPad)
                            ConfigField(label: "Logistics Delivery Note", icon: "note.text", text: $deliveryNote, prompt: "e.g. For 50kg bag")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("OPERATIONAL RADIUS (KM)")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(AppColors.secondary)
                                
                                HStack {
                                    Slider(value: Binding(get: { Double(deliveryRadius) ?? 25 }, set: { deliveryRadius = String(Int($0)) }), in: 1...200, step: 1)
                                        .tint(AppColors.primary)
                                    Text("\(deliveryRadius) KM")
                                        .font(.system(size: 14, weight: .bold))
                                        .frame(width: 60)
                                }
                            }
                            
                            HStack(spacing: 16) {
                                ConfigField(label: "Hub Latitude", icon: "location.fill", text: $hubLatitude, prompt: "21.1458")
                                ConfigField(label: "Hub Longitude", icon: "location.north.fill", text: $hubLongitude, prompt: "79.0882")
                            }
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // 3. Security Configuration
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Master Security Pathway")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Administrative Master Key", icon: "key.fill", text: $masterKey, prompt: "********** (Existing Master Key Saved)")
                        }
                        .padding(24)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(20)
                        
                        // Payment Gateway Configuration
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Payment Gateway Configuration")
                                .font(.system(size: 16, weight: .bold))
                            
                            ConfigField(label: "Razorpay Public Key", icon: "creditcard.fill", text: $rzpKey, prompt: "rzp_test_...")
                            ConfigField(label: "Razorpay Secret Key", icon: "lock.shield.fill", text: $rzpSecret, prompt: "********** (Encrypted & Saved)")
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
                        
                        if !message.isEmpty {
                            // Message is now shown in Alert, but we keep this for persistent error view if needed
                            Text(message)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(message.contains("Success") ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 20)
                        }
                        
                        Color.clear.frame(height: 100) // Space for floating button
                    }
                    .padding(22)
                }
            }
            
            // Floating Save Button (Always visible)
            if !isLoading {
                VStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.trigger(.medium)
                        saveSettings()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                Text("CONFIRM & APPLY SETTINGS")
                                    .font(.system(size: 14, weight: .black))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppColors.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .disabled(isSaving)
                }
            }
        }
        .navigationTitle("Global Protocol")
        .alert(message, isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {
                if message.contains("Successfully") {
                    dismiss()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    ProgressView().tint(AppColors.primary)
                } else {
                    Button(action: {
                        HapticManager.shared.trigger(.medium)
                        saveSettings()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
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
                        self.minOrderValue = json["min_order_value"] as? String ?? "1000"
                        self.freeDeliveryThreshold = json["free_delivery_threshold"] as? String ?? "5000"
                        self.referralReward = json["referral_reward_coins"] as? String ?? "50"
                        self.deliveryNote = json["delivery_note"] as? String ?? ""
                        self.deliveryRadius = json["delivery_radius"] as? String ?? "25"
                        self.hubLatitude = json["hub_latitude"] as? String ?? "21.1458"
                        self.hubLongitude = json["hub_longitude"] as? String ?? "79.0882"
                        self.masterKey = "" // Keep empty to indicate "hidden/unchanged"
                        self.rzpKey = json["razorpay_key"] as? String ?? APIConfig.razorpayKeyID
                        self.rzpSecret = "" // Keep empty to indicate "hidden/unchanged"
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
            "min_order_value": minOrderValue,
            "free_delivery_threshold": freeDeliveryThreshold,
            "referral_reward_coins": referralReward,
            "delivery_note": deliveryNote,
            "delivery_radius": deliveryRadius,
            "hub_latitude": hubLatitude,
            "hub_longitude": hubLongitude,
            "admin_master_key": masterKey,
            "razorpay_key": rzpKey,
            "razorpay_secret": rzpSecret
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
                        APIConfig.razorpayKeyID = rzpKey // Sync to app config
                        HapticManager.shared.notify(.success)
                        showStatusAlert = true
                    } else {
                        message = "Update Failed: \(response.message)"
                        showStatusAlert = true
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
