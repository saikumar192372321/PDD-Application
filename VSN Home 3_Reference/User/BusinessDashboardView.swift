import SwiftUI

// MARK: - Business Dashboard (Refined B2B Analytics)
struct BusinessDashboardView: View {
    let analytics: BusinessAnalytics
    @State private var isShowingCalculator = false
    @State private var isShowingCalendar = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Insights")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Real-time operational overview")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { 
                        isShowingCalculator = true 
                        HapticManager.shared.trigger(.light)
                    }) {
                        Image(systemName: "plus.forwardslash.minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                    
                    Button(action: { 
                        isShowingCalendar = true 
                        HapticManager.shared.trigger(.light)
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.primary)
                    Text("Smart Advisor")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("AI POWERED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    AdvisorLine(icon: "arrow.up.right.circle.fill", text: "Staples demand is up 22%. Consider restocking soon.", color: .green)
                    AdvisorLine(icon: "percent", text: "New bulk offer: 5% extra off on Oil > ₹5k.", color: AppColors.primary)
                    AdvisorLine(icon: "clock.fill", text: "Low dairy stock. Predicted stock-out in 48h.", color: .orange)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(AppColors.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Quick Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(
                    title: "Total Savings",
                    value: "₹" + (NumberFormatter.indian.string(from: NSNumber(value: analytics.totalSavings)) ?? "\(Int(analytics.totalSavings))"),
                    icon: "gift.fill",
                    color: AppColors.success
                )
                MetricCard(
                    title: "Total Orders",
                    value: "\(analytics.totalOrders)",
                    icon: "cart.fill",
                    color: .blue
                )
                MetricCard(
                    title: "Order Velocity",
                    value: "\(Int(analytics.orderVelocity))/mo",
                    icon: "shippingbox.fill",
                    color: .orange
                )
                MetricCard(
                    title: "Wallet Coins",
                    value: "\(analytics.walletCoins)",
                    icon: "coloncurrencysign.circle.fill",
                    color: .yellow
                )
            }
        }
        .padding(20)
        .background(
            BlurView(style: .systemThinMaterialLight)
                .opacity(0.6)
        )
        .cornerRadius(28)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .sheet(isPresented: $isShowingCalculator) {
            CalculatorView()
        }
        .sheet(isPresented: $isShowingCalendar) {
            CalendarView()
        }
    }
}


struct AdvisorLine: View {
    let icon: String
    let text: String
    let color: Color
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 16, height: 16)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(AppColors.textPrimary)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}
