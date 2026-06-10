import SwiftUI

struct ReferralDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var stats: ReferralStats?
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if isLoading {
                    ProgressView("Loading Stats...")
                } else if let stats = stats {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Card
                            VStack(spacing: 16) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColors.primary)
                                    .padding(.top, 20)
                                
                                Text("Refer & Earn Coins")
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text("Invite other business owners and both of you will receive 50 coins on their successful registration.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                                
                                // Referral Code Card
                                VStack(spacing: 8) {
                                    Text("YOUR REFERRAL CODE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    HStack {
                                        Text(stats.referral_code)
                                            .font(.system(size: 28, weight: .black, design: .monospaced))
                                            .foregroundColor(AppColors.primary)
                                        
                                        Button {
                                            UIPasteboard.general.string = stats.referral_code
                                            HapticManager.shared.notify(.success)
                                        } label: {
                                            Image(systemName: "doc.on.doc.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(AppColors.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.top, 10)
                                
                                Button(action: shareReferral) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up.fill")
                                        Text("Share with Partners")
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppColors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 30)
                            }
                            .padding(.bottom, 20)
                            .premiumCard()
                            .padding(.horizontal, 20)
                            
                            // Stats Section
                            HStack(spacing: 16) {
                                ReferralStatCard(title: "Total Referrals", value: "\(stats.total_referrals)", icon: "person.2.fill", color: .blue)
                                ReferralStatCard(title: "Coins Earned", value: "\(stats.total_earned)", icon: "coloncurrencysign.circle.fill", color: .orange)
                            }
                            .padding(.horizontal, 20)
                            
                            // Recent Referrals List
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Referrals")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.horizontal, 5)
                                
                                if stats.recent_referrals.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 32))
                                            .foregroundColor(AppColors.textSecondary.opacity(0.3))
                                        Text("No referrals yet. Start sharing!")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(AppColors.surfaceLight)
                                    .cornerRadius(16)
                                } else {
                                    VStack(spacing: 1) {
                                        ForEach(stats.recent_referrals) { ref in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(ref.name)
                                                        .font(.system(size: 15, weight: .semibold))
                                                    Text(ref.referee_email)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AppColors.textSecondary)
                                                }
                                                Spacer()
                                                Text("+\(ref.reward_amount)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(AppColors.success)
                                            }
                                            .padding(16)
                                            .background(AppColors.surfaceLight)
                                        }
                                    }
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Retry") { fetchStats() }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(40)
                }
            }
            .navigationTitle("Partner Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                    }
                }
            }
            .onAppear { fetchStats() }
        }
    }
    
    private func fetchStats() {
        isLoading = true
        errorMessage = ""
        let email = SessionManager.shared.userEmail
        guard let url = URL(string: APIConfig.getReferralStats + "?email=\(email)") else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(APIResponse<ReferralStats>.self, from: data)
                await MainActor.run {
                    if response.status == "success" {
                        self.stats = response.data
                    } else {
                        self.errorMessage = "Failed to load stats."
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Connection error. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func shareReferral() {
        guard let stats = stats else { return }
        let message = "Join VSN Home Wholesale Platform and get 50 bonus coins! Use my referral code: \(stats.referral_code)\n\nDownload app and register now."
        let av = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}

struct ReferralStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .black))
            
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}
