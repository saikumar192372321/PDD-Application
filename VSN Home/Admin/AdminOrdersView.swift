import SwiftUI

// MARK: - Admin Orders View (Refined B2B Order Management)
struct AdminOrdersView: View {
    @ObservedObject var productStore: GroceryProductStore
    @EnvironmentObject var tabBarState: TabBarState
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isGenerating = false
    
    var filteredOrders: [Order] {
        if searchText.isEmpty { return productStore.orders }
        return productStore.orders.filter { 
            $0.id.lowercased().contains(searchText.lowercased()) ||
            $0.userEmail.lowercased().contains(searchText.lowercased()) ||
            $0.status.rawValue.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Premium Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Order Management")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Button(action: exportCSV) {
                                Image(systemName: "square.and.arrow.up.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        Text("Track and fulfill business orders")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.textSecondary)
                            TextField("Search ID, Email, or Status", text: $searchText)
                                .font(.system(size: 14))
                        }
                        .padding(12)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    if filteredOrders.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(AppColors.primaryGradient.opacity(0.2))
                            Text(searchText.isEmpty ? "No pending orders" : "No results found")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredOrders) { order in
                                OrderRow(order: order, productStore: productStore, showShareSheet: $showShareSheet, shareURL: $shareURL, isGenerating: $isGenerating)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 100)
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
        .onAppear {
            Task { await productStore.fetchOrders() }
        }
        .refreshable {
            Task { await productStore.fetchOrders() }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ActivityView(activityItems: [url])
            }
        }
    }
    @State private var showCreateOrder = false
    
    private func exportCSV() {
        var csvString = "Order ID,Date,User Email,Total (INR),Status,Payment Status\n"
        for order in productStore.orders {
            let date = order.date.formatted(date: .numeric, time: .shortened).replacingOccurrences(of: ",", with: "")
            csvString += "\(order.id),\(date),\(order.userEmail),\(order.total),\(order.status.rawValue),\(order.paymentStatus.rawValue)\n"
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("VSN_Orders_Export.csv")
        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            self.shareURL = url
            self.showShareSheet = true
        } catch {
            print("Failed to export CSV: \(error)")
        }
    }
}

// MARK: - Order Row Card
struct OrderRow: View {
    let order: Order
    @ObservedObject var productStore: GroceryProductStore
    @Binding var showShareSheet: Bool
    @Binding var shareURL: URL?
    @Binding var isGenerating: Bool
    
    var body: some View {
        NavigationLink(destination: AdminOrderDetailView(productStore: productStore, order: order)) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: {
                            UIPasteboard.general.string = order.id
                            HapticManager.shared.notify(.success)
                        }) {
                            HStack(spacing: 4) {
                                Text("Order #\(order.id.prefix(8).uppercased())")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(AppColors.textPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text(order.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(order.userEmail)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    
                    Spacer()
                    
                    Text("₹\(Int(order.total))")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(AppColors.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                
                Divider()
                
                HStack {
                    OrderStatusBadge(status: order.status)
                    Spacer()
                    PaymentBadge(status: order.paymentStatus)
                    
                    Button(action: {
                        HapticManager.shared.trigger(.medium)
                        isGenerating = true
                        Task {
                            let url = InvoiceGenerator.generateInvoicePDF(order: order, selectedLanguage: .english)
                            await MainActor.run {
                                self.shareURL = url
                                self.isGenerating = false
                                if url != nil {
                                    self.showShareSheet = true
                                }
                            }
                        }
                    }) {
                        if isGenerating && shareURL == nil {
                            ProgressView().tint(AppColors.primary)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.primary)
                                .padding(8)
                                .background(AppColors.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary.opacity(0.4))
                        .padding(.leading, 4)
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
