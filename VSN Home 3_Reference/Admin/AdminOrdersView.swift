import SwiftUI

// MARK: - Admin Orders View (Refined B2B Order Management)
struct AdminOrdersView: View {
    @ObservedObject var productStore: GroceryProductStore
    @EnvironmentObject var tabBarState: TabBarState
    
    var body: some View {
        ZStack {
            AppBackground()
            
            Group {
                if productStore.orders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 44))
                            .foregroundColor(AppColors.textSecondary.opacity(0.3))
                        Text("No orders yet.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(productStore.orders) { order in
                                OrderRow(order: order, productStore: productStore)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Order Management")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateOrder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showCreateOrder) {
            AdminCreateOrderView(productStore: productStore)
                .environmentObject(tabBarState)
        }
    }
    @State private var showCreateOrder = false
}

// MARK: - Order Row Card
struct OrderRow: View {
    let order: Order
    @ObservedObject var productStore: GroceryProductStore
    
    var body: some View {
        NavigationLink(destination: AdminOrderDetailView(productStore: productStore, order: order)) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order.id.prefix(8).uppercased())")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(order.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Text(order.userEmail)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Spacer()
                    
                    Text("₹\(Int(order.total))")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(AppColors.primary)
                }
                
                Divider()
                
                HStack {
                    OrderStatusBadge(status: order.status)
                    Spacer()
                    PaymentBadge(status: order.paymentStatus)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        .padding(.leading, 8)
                }
            }
            .padding(16)
            .background(AppColors.surfaceLight)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Status Badge
struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
    
    private var color: Color {
        switch status {
        case .pending: return .orange
        case .processing: return .blue
        case .outForDelivery: return .purple
        case .delivered: return AppColors.success
        case .cancelled: return .red
        }
    }
}

// MARK: - Payment Badge
struct PaymentBadge: View {
    let status: PaymentStatus
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: status == .paid ? "checkmark.circle.fill" : "exclamationmark.circle")
                .font(.system(size: 10))
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(8)
    }
    
    private var color: Color {
        switch status {
        case .paid: return AppColors.success
        case .pending: return .orange
        case .failed, .refunded: return .red
        }
    }
}
