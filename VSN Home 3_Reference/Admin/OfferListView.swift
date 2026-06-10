import SwiftUI

// MARK: - Admin Offer List View
struct OfferListView: View {
    @ObservedObject var productStore: GroceryProductStore
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                headerPanel
                offersManifest
            }
            .padding(.vertical, 32)
        }
        .atmosphericBackground()
        .hidesTabBar()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddOfferView(productStore: productStore)) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("NEW DEPLOY")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundColor(AppColors.secondary)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.square.fill")
                    .foregroundColor(AppColors.secondary)
                Text("PROMOTIONAL PROTOCOLS")
                    .font(.system(size: 10, weight: .black))
                    .tracking(2)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("Bulk Deal Ledger")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            
            Text("Manage active wholesale discounts and promotional yield configurations.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
    
    private var offersManifest: some View {
        VStack(spacing: 16) {
            if productStore.bulkOffers.isEmpty {
                emptyStateView
            } else {
                ForEach(productStore.bulkOffers) { offer in
                    OfferRow(offer: offer, productStore: productStore)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppColors.textPrimary.opacity(0.02))
                    .frame(width: 120, height: 120)
                Image(systemName: "tag.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.textPrimary.opacity(0.1))
            }
            
            VStack(spacing: 8) {
                Text("NO ACTIVE OFFERS")
                    .font(.system(size: 14, weight: .black))
                    .tracking(2)
                    .foregroundColor(AppColors.textSecondary)
                Text("Launch new promotional sequences to stimulate wholesale volume.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }
}

// MARK: - Helper Views

struct OfferRow: View {
    let offer: BulkOffer
    @ObservedObject var productStore: GroceryProductStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DECODE: \(offer.id.prefix(8).uppercased())")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1)
                        .foregroundColor(AppColors.secondary)
                    Text(offer.title.uppercased())
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    if let index = productStore.bulkOffers.firstIndex(where: { $0.id == offer.id }) {
                        productStore.deleteOffer(at: IndexSet(integer: index))
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.6))
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Text(offer.description)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(3)
                .lineSpacing(4)
            
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                    if let amount = offer.discountAmount {
                        Text("₹\(Int(amount)) FLAT DISCOUNT")
                    } else if let percentage = offer.discountPercentage {
                        Text("\(Int(percentage * 100))% YIELD REBATE")
                    }
                }
                .font(.system(size: 10, weight: .black))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.primary.opacity(0.1))
                .foregroundColor(AppColors.primary)
                .clipShape(Capsule())
                
                Spacer()
                
                Text("MIN: ₹\(Int(offer.minOrderValue))")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(24)
        .background(AppColors.textPrimary.opacity(0.02))
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(AppColors.textPrimary.opacity(0.05), lineWidth: 1)
        )
    }
}
