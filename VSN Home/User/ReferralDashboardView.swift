import SwiftUI

struct ReferralDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var stats: ReferralStats?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var rewardAmount = 50
    
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
                                
                                Text("Invite other business owners and both of you will receive \(rewardAmount) coins on their successful registration.")
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
                                
                                ShareLink(item: "Join VSN Home Wholesale Platform and get \(rewardAmount) bonus coins! Use my referral code: \(stats.referral_code)\n\nDownload app and register now.") {
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
                            VStack(spacing: 16) {
                                HStack(spacing: 16) {
                                    ReferralStatCard(title: "Completed", value: "\(stats.completed_referrals ?? 0)", icon: "checkmark.seal.fill", color: AppColors.success)
                                    ReferralStatCard(title: "Pending", value: "\(stats.pending_referrals ?? 0)", icon: "hourglass.circle.fill", color: .orange)
                                }
                                
                                HStack(spacing: 16) {
                                    ReferralStatCard(title: "Total Referrals", value: "\(stats.total_referrals)", icon: "person.2.fill", color: .blue)
                                    ReferralStatCard(title: "Coins Earned", value: "\(stats.total_earned)", subtitle: "≈ ₹\(Int(Double(stats.total_earned) * 0.1))", icon: "pentagon.fill", color: .orange)
                                }
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
                                                VStack(alignment: .trailing, spacing: 4) {
                                                    Text("+\(ref.reward_amount)")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(ref.status == "completed" ? AppColors.success : .orange)
                                                    
                                                    if let status = ref.status {
                                                        Text(status.uppercased())
                                                            .font(.system(size: 8, weight: .black))
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(status == "completed" ? AppColors.success.opacity(0.1) : Color.orange.opacity(0.1))
                                                            .foregroundColor(status == "completed" ? AppColors.success : .orange)
                                                            .cornerRadius(4)
                                                    }
                                                }
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
                ToolbarItem(placement: .navigationBarLeading) {
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
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: APIConfig.getReferralStats + "?email=\(encodedEmail)") else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(APIResponse<ReferralStats>.self, from: data)
                await MainActor.run {
                    if response.status == "success", let stats = response.data {
                        self.stats = stats
                        // Also try to get reward from metadata if provided, or we can do a separate fetch
                        // For now, let's assume we fetch it separately or it's part of the stats response
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
        
        // Fetch current reward setting from support.php
        Task {
            if let url = URL(string: APIConfig.baseURL + "support.php"),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rewardStr = json["referral_reward_coins"] as? String,
               let amount = Int(rewardStr) {
                await MainActor.run {
                    self.rewardAmount = amount
                }
            }
        }
    }
    
}

struct ReferralStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .black))
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
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
