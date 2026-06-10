import SwiftUI

// MARK: - Offers View (Refined Bulk Deals)
struct OffersView: View {
    @ObservedObject var productStore: GroceryProductStore
    let selectedLanguage: AppLanguage
    @Binding var selectedOffer: BulkOffer?
    @Binding var selectedTab: GroceryAppView.Tab
    @EnvironmentObject var tabBarState: TabBarState
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Welcome Header (Subtle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maximize your margins with wholesale protocols and exclusive bulk incentives.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Active Deals Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(AppColors.primary)
                            Text("Active Reward Protocols")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            ForEach(productStore.bulkOffers) { offer in
                                BusinessOfferCard(
                                    offer: offer,
                                    isApplied: selectedOffer?.id == offer.id,
                                    action: {
                                        HapticManager.shared.trigger(.medium)
                                        withAnimation(.spring()) {
                                            selectedOffer = (selectedOffer?.id == offer.id) ? nil : offer
                                            if selectedOffer != nil { selectedTab = .cart }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // Feature Highlight
                    HStack(spacing: 16) {
                        Image(systemName: "clock.badge.checkmark.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.success)
                            .frame(width: 44, height: 44)
                            .background(AppColors.success.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real-time Delivery")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Logistics priority for bulk partners.")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, tabBarState.isHidden ? 20 : 130)
            }
        }
        .navigationTitle("Exclusive Deals")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BusinessOfferCard: View {
    let offer: BulkOffer
    let isApplied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isApplied ? AppColors.success.opacity(0.1) : Color(UIColor.secondarySystemFill))
                        .frame(width: 50, height: 50)
                    Image(systemName: isApplied ? "checkmark.seal.fill" : "gift.fill")
                        .foregroundColor(isApplied ? AppColors.success : AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(offer.description)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text("Min Order: ₹\(Int(offer.minOrderValue))")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(4)
                        
                        if isApplied {
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(AppColors.success)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
            }
            .padding(16)
            .background(AppColors.surfaceLight)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isApplied ? AppColors.success : Color.black.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }
}
