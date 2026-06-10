import SwiftUI

// MARK: - Product Details View (Modern B2B)
struct ProductDetailsView: View {
    let product: GroceryProduct
    let selectedLanguage: AppLanguage
    let addToCartAction: (GroceryProduct) -> Void

    @State private var addedToCart = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero Image ──────────────────────────────────────
                    ZStack {
                        Color(UIColor.secondarySystemGroupedBackground)
                        ProductImageView(imageName: product.image)
                            .frame(maxWidth: 280, maxHeight: 280)
                            .padding(32)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)

                    // ── Info Panel ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 24) {

                        // Brand + Stock status
                        HStack {
                            Text((product.details?.brand ?? "PREMIUM").uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(UIColor.tertiarySystemFill))
                                .clipShape(RoundedRectangle(cornerRadius: 7))

                            Spacer()

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(product.stockStatus.color)
                                    .frame(width: 7, height: 7)
                                Text(product.stockStatus.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(product.stockStatus.color)
                            }
                        }

                        // Name
                        Text(product.localizedName(for: selectedLanguage))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(3)

                        // Rating row
                        HStack(spacing: 6) {
                            HStack(spacing: 2) {
                                ForEach(0..<5) { i in
                                    Image(systemName: i < Int(product.rating.rounded()) ? "star.fill" : "star")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                }
                            }
                            Text(String(format: "%.1f", product.rating))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("(\(product.reviewCount) reviews)")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        // ── Pricing Block ──────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("₹\(Int(product.wholesalePrice))")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)

                                Text(product.formattedRetailPrice)
                                    .font(.system(size: 18, weight: .medium))
                                    .strikethrough()
                                    .foregroundColor(AppColors.textSecondary.opacity(0.6))

                                if product.discountPercentage > 0 {
                                    Text("\(product.discountPercentage)% off")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.success)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppColors.success.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }

                            if product.savings > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "indianrupeesign.circle.fill")
                                        .foregroundColor(AppColors.secondary)
                                    Text("You save ₹\(Int(product.savings)) per unit")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.secondary)
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.secondary.opacity(0.18), lineWidth: 1)
                        )

                        // ── Coin Offer Highlight ────────────────────────
                        if let offer = product.coinOffer {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "coloncurrencysign.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.orange)
                                    Text("Loyalty Reward")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(offer.rewardCoins) Coins")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(.orange)
                                }
                                
                                Text(offer.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(2)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 10))
                                    Text("Earned upon purchase of \(offer.thresholdQuantity) or more units.")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(AppColors.textSecondary.opacity(0.8))
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // ── Key Specs Grid ─────────────────────────────
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            InfoTile(label: "Min. Order Qty", value: "\(product.minOrderQty) units", icon: "shippingbox.fill", color: AppColors.primary)
                            InfoTile(label: "Category", value: product.details?.category.rawValue ?? "General", icon: "tag.fill", color: AppColors.accent)
                            InfoTile(label: "Net Quantity", value: product.details?.netQuantity ?? "N/A", icon: "scalemass.fill", color: AppColors.secondary)
                            InfoTile(label: "Tax", value: "GST Inclusive", icon: "doc.text.fill", color: AppColors.info)
                        }

                        // ── Product Description ────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Product Details")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            Text(product.details?.description ?? "Premium quality product for wholesale")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(6)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .hidesTabBar()
        .safeAreaInset(edge: .bottom) {
            // ── Bottom CTA ─────────────────────────────────────────────
            VStack(spacing: 0) {
                Divider()
                Button {
                    guard !product.isOutOfStock else { return }
                    HapticManager.shared.notify(.success)
                    withAnimation { addedToCart = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { addedToCart = false }
                    }
                    addToCartAction(product)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: addedToCart ? "checkmark.circle.fill" : (product.isOutOfStock ? "bell.badge.fill" : "cart.fill.badge.plus"))
                            .font(.system(size: 18, weight: .semibold))
                        Text(addedToCart ? "Added to Cart!" : (product.isOutOfStock ? "Notify When Available" : "Add to Cart"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        addedToCart
                            ? AnyShapeStyle(AppColors.success)
                            : (product.isOutOfStock
                                ? AnyShapeStyle(Color(UIColor.tertiarySystemFill))
                                : AnyShapeStyle(AppColors.primaryGradient))
                    )
                    .foregroundColor(product.isOutOfStock ? AppColors.textSecondary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .animation(.spring(response: 0.3), value: addedToCart)
                }
                .disabled(product.isOutOfStock)
                .background(.regularMaterial)
            }
        }
    }
}

// MARK: - Info Tile
struct InfoTile: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.surfaceLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// Backwards-compat alias so existing callers compile
typealias AdvancedInfoTile = InfoTile
