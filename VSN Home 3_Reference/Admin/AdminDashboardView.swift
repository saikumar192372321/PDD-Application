import SwiftUI
import Charts

// MARK: - Admin Dashboard View (Refined B2B Admin)
struct AdminDashboardView: View {
    @ObservedObject var productStore: GroceryProductStore
    @State private var selectedTimeFrame: TimeFrame = .daily
    
    enum TimeFrame: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var totalRevenue: Double { productStore.adminAnalytics?.kpi.totalRevenue ?? 0 }
    var totalProfit: Double { productStore.orders.reduce(0) { $0 + $1.totalProfit } } // Simplified for real data or keep as is if backend totalRevenue is preferred
    var activeOrders: Int { productStore.adminAnalytics?.kpi.totalOrders ?? 0 }
    var uniqueCustomers: Int { productStore.adminAnalytics?.kpi.uniqueCustomers ?? 0 }

    var body: some View {
        ZStack {
            AppBackground()

            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Business Command")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Administrative overview & real-time analytics.")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    
                    // Timeframe Picker
                    Picker("", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 22)
                    
                    // Primary Metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: RevenueDetailView(data: productStore.adminAnalytics?.revenue ?? [])) {
                            AdminMetricCard(title: "Revenue", value: "₹\(Int(totalRevenue))", icon: "indianrupeesign.circle.fill", color: AppColors.primary)
                        }
                        
                        NavigationLink(destination: AdminOrdersView(productStore: productStore)) {
                            AdminMetricCard(title: "Orders", value: "\(activeOrders)", icon: "shippingbox.fill", color: .blue)
                        }
                        
                        NavigationLink(destination: AdminUsersView(productStore: productStore)) {
                            AdminMetricCard(title: "Customers", value: "\(uniqueCustomers)", icon: "person.2.fill", color: .purple)
                        }
                        
                        NavigationLink(destination: OfferListView(productStore: productStore)) {
                            AdminMetricCard(title: "Discounts", value: "₹\(Int(productStore.adminAnalytics?.kpi.totalDiscounts ?? 0))", icon: "tag.fill", color: .orange)
                        }
                        
                        NavigationLink(destination: ConfigHubView()) {
                            AdminMetricCard(title: "Protocols", value: "Active", icon: "gearshape.2.fill", color: .gray)
                        }
                    }
                    .padding(.horizontal, 22)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Critical Alerts
                    if !productStore.products.filter({ $0.stockStatus != .inStock }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Inventory Alerts")
                                .font(.system(size: 16, weight: .bold))
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(productStore.products.filter { $0.stockStatus != .inStock }) { product in
                                        NavigationLink(destination: ProductListView(productStore: productStore)) {
                                            HStack(spacing: 10) {
                                                Circle().fill(product.stockStatus == .outOfStock ? .red : .orange).frame(width: 8, height: 8)
                                                Text(product.name).font(.system(size: 13, weight: .semibold))
                                                Text(product.stockStatus.rawValue).font(.system(size: 11)).foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(AppColors.surfaceLight)
                                            .cornerRadius(12)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // Sales Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Revenue Velocity")
                            .font(.system(size: 16, weight: .bold))
                        
                        Chart {
                            ForEach(productStore.adminAnalytics?.revenue ?? []) { data in
                                AreaMark(x: .value("Label", data.label), y: .value("Revenue", data.value))
                                    .foregroundStyle(AppColors.primary.opacity(0.1).gradient)
                                LineMark(x: .value("Label", data.label), y: .value("Revenue", data.value))
                                    .foregroundStyle(AppColors.primary)
                                    .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)

                    // Product Usage Chart (NEW)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Product Usage Status")
                            .font(.system(size: 16, weight: .bold))
                        
                        Chart {
                            ForEach(productStore.adminAnalytics?.products ?? []) { data in
                                BarMark(
                                    x: .value("Qty", data.value),
                                    y: .value("Product", data.label)
                                )
                                .foregroundStyle(AppColors.primaryGradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: CGFloat(max(200, (productStore.adminAnalytics?.products.count ?? 0) * 30)))
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    
                    // Order Status Distribution
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order fulfillment status")
                            .font(.system(size: 16, weight: .bold))
                        
                        Chart {
                            ForEach(productStore.adminAnalytics?.statuses ?? []) { data in
                                BarMark(x: .value("Status", data.label), y: .value("Count", data.value))
                                    .foregroundStyle(by: .value("Status", data.label))
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding(20)
                    .background(AppColors.surfaceLight)
                    .cornerRadius(20)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Admin Dashboard")
        .refreshable {
            await productStore.fetchAdminAnalytics(period: selectedTimeFrame.rawValue.lowercased())
            await productStore.fetchOrders()
        }
        .onAppear {
            Task {
                await productStore.fetchAdminAnalytics(period: selectedTimeFrame.rawValue.lowercased())
                await productStore.fetchOrders()
            }
        }
        .onChange(of: selectedTimeFrame) { newValue in
            Task {
                await productStore.fetchAdminAnalytics(period: newValue.rawValue.lowercased())
            }
        }
    }
}

// MARK: - Revenue Detail View
struct RevenueDetailView: View {
    let data: [AdminAnalytics.DataPoint]
    
    var body: some View {
        ZStack {
            AppBackground()

            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(data) { point in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(point.label)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Sales Period")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Text("₹\(Int(point.value))")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(AppColors.primary)
                        }
                        .padding(20)
                        .background(AppColors.surfaceLight)
                        .cornerRadius(16)
                        .premiumCard()
                    }
                }
                .padding(22)
            }
        }
        .navigationTitle("Revenue Breakdown")
        .hidesTabBar()
    }
}

struct AdminMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 18, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textSecondary.opacity(0.3))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .black))
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceLight)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Mock Data
struct SalesData: Identifiable { let id = UUID(); let day: String; let sales: Double }
struct CategorySalesData: Identifiable { let id = UUID(); let category: String; let sales: Double }

let mockSalesData: [SalesData] = [
    SalesData(day: "Mon", sales: 4500), SalesData(day: "Tue", sales: 7200),
    SalesData(day: "Wed", sales: 5100), SalesData(day: "Thu", sales: 9800),
    SalesData(day: "Fri", sales: 8400), SalesData(day: "Sat", sales: 12500)
]

let mockCategorySales: [CategorySalesData] = [
    CategorySalesData(category: "Staples", sales: 15000), CategorySalesData(category: "Oil", sales: 8500),
    CategorySalesData(category: "Dairy", sales: 5600), CategorySalesData(category: "Snacks", sales: 4200)
]
