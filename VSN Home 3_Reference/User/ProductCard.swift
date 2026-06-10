import SwiftUI

// MARK: - Product Card (Wholesale Style, Modern B2B)
struct ProductCard: View {
    let product: GroceryProduct
    let selectedLanguage: AppLanguage
    @Binding var cartItems: [GroceryCartItem]

    @State private var isPressed = false

    var currentQuantity: Int {
        cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
        }
        .background(
            BlurView(style: .systemThinMaterialLight)
                .opacity(0.8)
        )
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private func updateQuantity(_ delta: Int) {
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            let newQty = cartItems[index].quantity + delta
            if newQty <= 0 {
                cartItems.remove(at: index)
                HapticManager.shared.trigger(.light)
            } else {
                cartItems[index].quantity = newQty
                HapticManager.shared.trigger(.medium)
            }
        } else if delta > 0 {
            cartItems.append(GroceryCartItem(product: product, quantity: delta))
            HapticManager.shared.notify(.success)
        }
    }
}

// MARK: - Subviews
private extension ProductCard {
    var imageSection: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                ProductImageView(imageName: product.image)
                    .scaleEffect(0.85)
                    .padding(12)
            }
            .frame(height: 130)

            if product.isTrending {
                Label("HOT", systemImage: "flame.fill")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(8)
            }

            if product.discountPercentage > 0 {
                Text("\(product.discountPercentage)% OFF")
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(8)
            }

            if product.isOutOfStock {
                Color.black.opacity(0.55)
                    .frame(height: 130)
                    .overlay(
                        Text("Out of Stock")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.85))
                            .clipShape(Capsule())
                    )
            }
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 14))
    }
    
    var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text((product.details?.brand ?? "GENERIC").uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(0.5)

                Text(product.localizedName(for: selectedLanguage))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)
                    .frame(minHeight: 36, alignment: .topLeading)
            }

            if product.savings > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill").font(.system(size: 8))
                    Text("Save ₹\(Int(product.savings))").font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(AppColors.secondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(AppColors.secondary.opacity(0.10)).clipShape(Capsule())
            }
            
            if let offer = product.coinOffer {
                HStack(spacing: 3) {
                    Image(systemName: "coloncurrencysign.circle.fill").font(.system(size: 8))
                    Text("\(offer.rewardCoins) COINS on \(offer.thresholdQuantity)+")
                        .font(.system(size: 9, weight: .black))
                }
                .foregroundColor(.orange).padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.orange.opacity(0.10)).clipShape(Capsule())
            }

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(product.formattedRetailPrice).font(.system(size: 10, weight: .medium)).strikethrough().foregroundColor(AppColors.textSecondary.opacity(0.6))
                    Text(product.formattedWholesalePrice).font(.system(size: 16, weight: .bold)).foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                if currentQuantity > 0 {
                    AmazonStepper(quantity: currentQuantity, onIncrement: { updateQuantity(1) }, onDecrement: { updateQuantity(-1) })
                } else {
                    plusButton
                }
            }

            Text("MOQ: \(product.minOrderQty ?? 1) units")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(12)
    }
    
    var plusButton: some View {
        Button(action: {
            guard !product.isOutOfStock else { return }
            HapticManager.shared.trigger(.medium)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { withAnimation { isPressed = false } }
            updateQuantity(product.minOrderQty ?? 1)
        }) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white).frame(width: 34, height: 34)
                .background(product.isOutOfStock ? Color(UIColor.tertiaryLabel) : AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scaleEffect(isPressed ? 0.88 : 1.0)
        }
        .disabled(product.isOutOfStock)
    }
}

// MARK: - Trending Product Card (Horizontal, Clean)
struct TrendingProductCard: View {
    let product: GroceryProduct
    let selectedLanguage: AppLanguage
    @Binding var cartItems: [GroceryCartItem]

    var currentQuantity: Int {
        cartItems.first(where: { $0.product.id == product.id })?.quantity ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageSection
            contentSection
        }
        .background(BlurView(style: .systemThinMaterialLight).opacity(0.8))
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Color(UIColor.secondarySystemGroupedBackground)
                ProductImageView(imageName: product.image)
                    .scaleEffect(0.82)
                    .padding(12)
            }
            .frame(width: 172, height: 130)

            if product.discountPercentage > 0 {
                Text("\(product.discountPercentage)% OFF")
                    .font(.system(size: 9, weight: .heavy))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(AppColors.primary).foregroundColor(.white)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 8, bottomTrailingRadius: 0, topTrailingRadius: 14))
            }
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 14))
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text((product.details?.brand ?? "GENERIC").uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                Text(product.localizedName(for: selectedLanguage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }

            if product.savings > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill").font(.system(size: 8))
                    Text("Save ₹\(Int(product.savings))").font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(AppColors.secondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(AppColors.secondary.opacity(0.10)).clipShape(Capsule())
            }
        }
        .padding(12)
    }
}

// MARK: - Amazon Style Stepper
struct AmazonStepper: View {
    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Image(systemName: quantity == 1 ? "trash" : "minus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.04))
            }
            
            Text("\(quantity)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 38, height: 32)
                .background(Color.white)
            
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.04))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
