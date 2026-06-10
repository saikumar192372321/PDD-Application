import SwiftUI
import Charts

// MARK: - Admin Dashboard View (Refined B2B Admin)
struct AdminDashboardView: View {
    @ObservedObject var productStore: GroceryProductStore
    @ObservedObject var notificationStore: NotificationStore
    @Binding var selectedTab: AdminTabView.AdminTab
    @Binding var selectedLanguage: AppLanguage
    
    @State private var selectedTimeFrame: TimeFrame = .daily
    @State private var isShowingCalculator = false
    @State private var isShowingCalendar = false

    enum TimeFrame: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var totalRevenue: Double { productStore.adminAnalytics?.kpi.totalRevenue ?? 0 }
    var totalProfit: Double { productStore.orders.reduce(0) { $0 + $1.totalProfit } }
    var activeOrders: Int { productStore.adminAnalytics?.kpi.totalOrders ?? 0 }
    var uniqueCustomers: Int { productStore.adminAnalytics?.kpi.uniqueCustomers ?? 0 }
    
    var alertProducts: [GroceryProduct] {
        productStore.products.filter { $0.stockStatus != .inStock }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            // Decorative background blur
            Circle()
                .fill(AppColors.primary.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -150, y: -100)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                        .padding(.top, 16) // Added a bit more air at the top
                    
                    metricsGridSection
                    
                    alertsSection
                    
                    chartsSection
                }
                .padding(.bottom, 100) // Ensure last item isn't covered by tab bar
            }
        }
        .navigationBarHidden(true)
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
        .sheet(isPresented: $isShowingCalculator) {
            CalculatorView()
        }
        .sheet(isPresented: $isShowingCalendar) {
            CalendarView()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppText.get("admin_portal", lang: selectedLanguage).uppercased())
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(AppText.get("tab_insights", lang: selectedLanguage))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                
                Button(action: {
                    HapticManager.shared.trigger(.light)
                    Task { await productStore.fetchAdminAnalytics(period: selectedTimeFrame.rawValue.lowercased()) }
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.primaryGradient)
                }
            }
            
            // Timeframe Picker
            HStack(spacing: 8) {
                ForEach(TimeFrame.allCases, id: \.self) { frame in
                    Button(action: {
                        HapticManager.shared.trigger(.light)
                        selectedTimeFrame = frame
                    }) {
                        Text(frame.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedTimeFrame == frame ? AnyShapeStyle(AppColors.primaryGradient) : AnyShapeStyle(AppColors.surface))
                            .foregroundColor(selectedTimeFrame == frame ? .white : AppColors.textPrimary)
                            .clipShape(Capsule())
                            .shadow(color: selectedTimeFrame == frame ? AppColors.primary.opacity(0.2) : Color.clear, radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 24) // Slightly wider horizontal padding
    }
    
    @ViewBuilder
    private var metricsGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            NavigationLink {
                RevenueDetailView(data: productStore.adminAnalytics?.revenue ?? [])
            } label: {
                AdminMetricCard(title: "REVENUE", value: "₹\(Int(totalRevenue))", icon: "indianrupeesign.circle.fill", color: AppColors.primary, trend: "+12%")
            }
            .buttonStyle(.plain)
            
            Button(action: {
                HapticManager.shared.trigger(.medium)
                selectedTab = .orders
            }) {
                AdminMetricCard(title: AppText.get("tab_orders", lang: selectedLanguage).uppercased(), value: "\(activeOrders)", icon: "shippingbox.fill", color: .blue, trend: "+5")
            }
            .buttonStyle(.plain)
            
            Button(action: {
                HapticManager.shared.trigger(.medium)
                selectedTab = .partners
            }) {
                AdminMetricCard(title: "CUSTOMERS", value: "\(uniqueCustomers)", icon: "person.2.fill", color: .purple, trend: "+2")
            }
            .buttonStyle(.plain)
            
            NavigationLink {
                OfferListView(productStore: productStore)
            } label: {
                AdminMetricCard(title: "DISCOUNTS", value: "₹\(Int(productStore.adminAnalytics?.kpi.totalDiscounts ?? 0))", icon: "tag.fill", color: .orange, trend: "Used")
            }
            .buttonStyle(.plain)

            NavigationLink {
                ConfigHubView()
            } label: {
                AdminMetricCard(title: "PROTOCOLS", value: "Active", icon: "gearshape.2.fill", color: .gray, trend: "Secure")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var alertsSection: some View {
        let alerts = alertProducts
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Inventory Alerts")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("\(alerts.count) items")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(alerts) { product in
                            NavigationLink(destination: ProductListView(productStore: productStore, notificationStore: notificationStore)) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(product.stockStatus == .outOfStock ? Color.red : Color.orange)
                                        .frame(width: 8, height: 8)
                                        .glow(color: product.stockStatus == .outOfStock ? .red : .orange, radius: 4)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(product.stockStatus.rawValue.uppercased())
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(product.stockStatus == .outOfStock ? Color.red.opacity(0.1) : Color.orange.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        VStack(spacing: 24) {
            // Sales Trend
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Sales Trend", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text("Last \(selectedTimeFrame.rawValue)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                }

                Chart {
                    ForEach(productStore.adminAnalytics?.revenue ?? []) { data in
                        AreaMark(x: .value("Label", data.label), y: .value("Revenue", data.value))
                            .foregroundStyle(AppColors.primary.opacity(0.1).gradient)
                        LineMark(x: .value("Label", data.label), y: .value("Revenue", data.value))
                            .foregroundStyle(AppColors.primaryGradient)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                            .symbolSize(40)
                    }
                }
                .frame(height: 180)
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)

            // Top Products
            VStack(alignment: .leading, spacing: 16) {
                Label("Performance Leaders", systemImage: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Chart {
                    ForEach(productStore.adminAnalytics?.products ?? []) { data in
                        BarMark(
                            x: .value("Qty", data.value),
                            y: .value("Product", data.label)
                        )
                        .foregroundStyle(AppColors.primaryGradient)
                        .cornerRadius(6)
                    }
                }
                .frame(height: CGFloat(max(180, (productStore.adminAnalytics?.products.count ?? 0) * 40)))
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)

            // Order Status Distribution (From VSN Home 3)
            VStack(alignment: .leading, spacing: 16) {
                Label("Fulfillment Lifecycle", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Chart {
                    ForEach(productStore.adminAnalytics?.statuses ?? []) { data in
                        BarMark(x: .value("Status", data.label), y: .value("Count", data.value))
                            .foregroundStyle(by: .value("Status", data.label))
                            .cornerRadius(6)
                    }
                }
                .frame(height: 180)
            }
            .padding(20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 120)
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
                        .padding(16)
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
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
                Text(trend)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(trend.contains("+") ? AppColors.success : AppColors.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(trend.contains("+") ? AppColors.success.opacity(0.1) : Color.black.opacity(0.05))
                    .clipShape(Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        .scaleEffect(1.0) // Placeholder for future animations or just ensuring it's a discrete layer
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

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AdminDashboardView(productStore: GroceryProductStore(), notificationStore: NotificationStore(), selectedTab: .constant(.insights), selectedLanguage: .constant(.english))
        }
    }
}

