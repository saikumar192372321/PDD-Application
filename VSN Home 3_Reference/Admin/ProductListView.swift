import SwiftUI

// MARK: - Admin Product List (Modern B2B Catalog)
struct ProductListView: View {
    @ObservedObject var productStore: GroceryProductStore
    @State private var productToDelete: GroceryProduct?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(productStore.products) { product in
                        ProductInventoryRow(
                            product: product,
                            onDelete: {
                                HapticManager.shared.trigger(.medium)
                                productToDelete = $0
                                showDeleteConfirmation = true
                            },
                            onUpdateStatus: { updated in
                                Task { await productStore.updateProduct(updated) }
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Inventory Catalog")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                NavigationLink(destination: OfferListView(productStore: productStore)) {
                    Image(systemName: "tag")
                }
                NavigationLink(destination: AddProductView(productStore: productStore)) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Delete Product", isPresented: $showDeleteConfirmation, presenting: productToDelete) { product in
            Button("Delete", role: .destructive) {
                if let index = productStore.products.firstIndex(where: { $0.id == product.id }) {
                    productStore.deleteProduct(at: IndexSet(integer: index))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { product in
            Text("Are you sure you want to remove '\(product.name)'? This action cannot be undone.")
        }
    }
}

private struct ProductInventoryRow: View {
    let product: GroceryProduct
    let onDelete: (GroceryProduct) -> Void
    let onUpdateStatus: (GroceryProduct) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ProductImageView(imageName: product.image)
                .frame(width: 70, height: 70)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(product.name)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    StatusBadge(status: product.stockStatus)
                }
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wholesale Price")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                        Text("₹\(Int(product.wholesalePrice))")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(StockStatus.allCases, id: \.self) { status in
                            Button(status.rawValue) {
                                var updated = product
                                updated.stockStatus = status
                                onUpdateStatus(updated)
                            }
                        }
                    } label: {
                        Text("Update Stock")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.primary.opacity(0.1))
                            .foregroundColor(AppColors.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { onDelete(product) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.red.opacity(0.6))
                            .padding(8)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
    }
}

struct StatusBadge: View {
    let status: StockStatus
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 9, weight: .black))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.1))
            .foregroundColor(status.color)
            .cornerRadius(6)
    }
}
