import SwiftUI
import Combine

// MARK: - Product Store
@MainActor
class GroceryProductStore: ObservableObject {
    @Published var bulkOffers: [BulkOffer] = []
    @Published var products: [GroceryProduct] = []
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var adminAnalytics: AdminAnalytics?
    
    private let baseURL = APIConfig.baseURL // Update this in APIConfig.swift if testing on real device
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                return date
            }
            // Fallback for newer format
            let iso8601WithFractional = ISO8601DateFormatter()
            iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601WithFractional.date(from: dateString) {
                return date
            }
            return Date() // Last resort to prevent crash
        })
        return decoder
    }
    
    init() {
        // Load local data first for a responsive feel.
        // NOTE: Orders are intentionally NOT loaded here — they must be
        // fetched with a specific user email (via fetchOrders(email:isAdmin:))
        // called by GroceryAppView after login, to avoid showing one user's
        // orders to a different user.
        loadLocalData()
        
        Task {
            await fetchProducts()
            await fetchOffers()
            // Do NOT call fetchOrders() here — no email context yet.
        }
    }
    
    // MARK: - Persistence
    private var productsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("persisted_products.json")
    }
    
    private var offersURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("persisted_offers.json")
    }
    
    private func ordersURL(for email: String) -> URL {
        let safeEmail = email.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("persisted_orders_\(safeEmail).json")
    }
    
    private func saveLocalProducts() {
        try? JSONEncoder().encode(products).write(to: productsURL)
    }
    
    private func saveLocalOffers() {
        try? JSONEncoder().encode(bulkOffers).write(to: offersURL)
    }
    
    func saveLocalOrders(for email: String) {
        try? JSONEncoder().encode(orders).write(to: ordersURL(for: email))
    }
    
    func loadLocalData(for email: String? = nil) {
        // Load Products
        if let data = try? Data(contentsOf: productsURL),
           let saved = try? decoder.decode([GroceryProduct].self, from: data) {
            self.products = saved
        } else {
            self.products = MockData.products
        }
        
        // Load Offers
        if let data = try? Data(contentsOf: offersURL),
           let saved = try? decoder.decode([BulkOffer].self, from: data) {
            self.bulkOffers = saved
        } else {
            self.bulkOffers = MockData.offers
        }
        
        // Load Orders if email is provided
        if let email = email {
            if let data = try? Data(contentsOf: ordersURL(for: email)),
               let saved = try? decoder.decode([Order].self, from: data) {
                self.orders = saved
            } else {
                self.orders = []
            }
        } else {
            self.orders = []
        }
    }
    
    func fetchProducts() async {
        guard let url = URL(string: baseURL + "get_products.php") else { return }
        isLoading = true
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(APIResponse<[GroceryProduct]>.self, from: data)
            if response.status == "success" && !response.data.isEmpty {
                self.products = response.data
                saveLocalProducts()
            }
        } catch {
            print("Fetch products failed: \(error)")
        }
        isLoading = false
    }
    
    func fetchOffers() async {
        guard let url = URL(string: baseURL + "get_offers.php") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(APIResponse<[BulkOffer]>.self, from: data)
            if response.status == "success" {
                self.bulkOffers = response.data
            }
        } catch {
            print("Fetch offers failed, using mock data: \(error)")
            if self.bulkOffers.isEmpty {
                self.bulkOffers = MockData.offers
            }
        }
    }

    func fetchAdminAnalytics(period: String = "weekly") async {
        guard let url = URL(string: baseURL + "admin_analytics.php?period=\(period)") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(APIResponse<AdminAnalytics>.self, from: data)
            if response.status == "success" {
                self.adminAnalytics = response.data
            }
        } catch {
            print("Fetch admin analytics failed: \(error)")
        }
    }

    func fetchOrders(email: String? = nil, isAdmin: Bool = true) async {
        var urlString = baseURL + "get_orders.php?isAdmin=\(isAdmin)"
        if let email = email, let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&userEmail=\(encodedEmail)"
        }
        
        guard let url = URL(string: urlString) else { 
            print("❌ Invalid Orders URL: \(urlString)")
            return 
        }
        
        print("🛰️ Fetching orders from: \(url.absoluteString)")
        
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                 print("⚠️ Server returned status code: \(httpResponse.statusCode)")
            }
            let apiResponse = try decoder.decode(APIResponse<[Order]>.self, from: data)
            if apiResponse.status == "success" {
                await MainActor.run {
                    if !apiResponse.data.isEmpty {
                        self.orders = apiResponse.data
                        if let userEmail = email { saveLocalOrders(for: userEmail) }
                    } else if self.orders.isEmpty {
                        self.orders = []
                    }
                }
            } else {
                print("⚠️ Server reported issue: \(apiResponse.message ?? "No detailed reason provided.")")
            }
        } catch DecodingError.keyNotFound(let key, let context) {
            print("❌ Order Fetch (Key Missing): \(key.stringValue) at \(context.codingPath)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("❌ Order Fetch (Value Null): \(type) at \(context.codingPath)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("❌ Order Fetch (Type Wrong): \(type) at \(context.codingPath)")
        } catch {
            print("❌ Fetch orders failed: \(error.localizedDescription)")
        }
    }
    
    func addProduct(_ product: GroceryProduct) async {
        guard let url = URL(string: baseURL + "add_product.php") else { return }
        
        // Optimistic / Demo update
        self.products.insert(product, at: 0)
        saveLocalProducts()
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            request.httpBody = try JSONEncoder().encode(product)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(SimpleResponse.self, from: data)
            
            if response.status == "success" {
                await fetchProducts()
            }
        } catch {
            print("Add product API failed, keeping local demo version: \(error)")
        }
    }
    
    func deleteProduct(at offsets: IndexSet) {
        let productsToDelete = offsets.map { products[$0] }
        
        // Local update
        self.products.remove(atOffsets: offsets)
        saveLocalProducts()
        
        Task {
            for product in productsToDelete {
                guard let url = URL(string: baseURL + "delete_product.php") else { continue }
                
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("close", forHTTPHeaderField: "Connection")
                    request.timeoutInterval = 30
                    let body = ["id": product.id]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (data, _) = try await URLSession.shared.data(for: request)
                    let _ = try decoder.decode(SimpleResponse.self, from: data)
                } catch {
                    print("Delete product API failed: \(error)")
                }
            }
            // Optional: await fetchProducts() // Refetch if needed
        }
    }
    
    func updateProduct(_ product: GroceryProduct) async {
        // Local update
        if let index = self.products.firstIndex(where: { $0.id == product.id }) {
            self.products[index] = product
            saveLocalProducts()
        }
        
        guard let url = URL(string: baseURL + "update_stock.php") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            
            let body: [String: Any] = [
                "id": product.id,
                "stockStatus": product.stockStatus.rawValue
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let _ = try decoder.decode(SimpleResponse.self, from: data)
            
            await fetchProducts()
        } catch {
            print("Update product API failed, kept local change: \(error)")
        }
    }

    func updateOrderStatus(_ order: Order) async {
        // Local update
        if let index = self.orders.firstIndex(where: { $0.id == order.id }) {
            self.orders[index] = order
            saveLocalOrders(for: order.userEmail)
        }
        
        guard let url = URL(string: baseURL + "update_order_status.php") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            
            let body: [String: Any] = [
                "id": order.id,
                "status": order.status.rawValue,
                "paymentStatus": order.paymentStatus.rawValue,
                "customDeliveryDate": order.customDeliveryDate != nil ? ISO8601DateFormatter().string(from: order.customDeliveryDate!) : (NSNull() as Any)
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let _ = try decoder.decode(SimpleResponse.self, from: data)
            
            await fetchOrders()
        } catch {
            print("Update order failed: \(error)")
        }
    }

    func addOffer(_ offer: BulkOffer) async {
        guard let url = URL(string: baseURL + "add_offer.php") else { return }
        
        self.bulkOffers.insert(offer, at: 0)
        saveLocalOffers()
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("close", forHTTPHeaderField: "Connection")
            request.timeoutInterval = 30
            request.httpBody = try JSONEncoder().encode(offer)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try decoder.decode(SimpleResponse.self, from: data)
            
            if response.status == "success" {
                await fetchOffers()
            }
        } catch {
            print("Add offer failed: \(error)")
        }
    }
    
    func deleteOffer(at offsets: IndexSet) {
        let offersToDelete = offsets.map { bulkOffers[$0] }
        self.bulkOffers.remove(atOffsets: offsets)
        saveLocalOffers()
        
        Task {
            for offer in offersToDelete {
                guard let url = URL(string: baseURL + "delete_offer.php") else { continue }
                
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("close", forHTTPHeaderField: "Connection")
                    request.timeoutInterval = 30
                    let body = ["id": offer.id]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    
                    let (data, _) = try await URLSession.shared.data(for: request)
                    let _ = try decoder.decode(SimpleResponse.self, from: data)
                } catch {
                    print("Delete offer failed: \(error)")
                }
            }
            await fetchOffers()
        }
    }
    
    func calculateAnalytics(for email: String, currentBalance: Int) -> BusinessAnalytics {
        let targetEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let userOrders = orders.filter { $0.userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == targetEmail }
        
        if userOrders.isEmpty {
            return BusinessAnalytics(
                totalSavings: 0,
                orderVelocity: 0,
                growthPercentage: 0,
                walletCoins: currentBalance,
                totalOrders: 0,
                nextBigDealDate: nil
            )
        }
        
        let totalSavings = userOrders.reduce(0) { $0 + $1.items.reduce(0) { $0 + ($1.product.savings * Double($1.quantity)) } }
        let totalCoins = userOrders.reduce(0) { $0 + $1.coinsEarned }
        
        // Calculate velocity (orders per month)
        let firstOrderDate = userOrders.map { $0.date }.min() ?? Date()
        let monthsPassed = max(1.0, Calendar.current.dateComponents([.month], from: firstOrderDate, to: Date()).month.map { Double($0) } ?? 1.0)
        let velocity = Double(userOrders.count) / monthsPassed
        
        // Mock growth based on order count
        let growth = userOrders.count > 1 ? 22.4 : 0.0
        
        return BusinessAnalytics(
            totalSavings: totalSavings,
            orderVelocity: velocity,
            growthPercentage: growth,
            walletCoins: currentBalance > 0 ? currentBalance : totalCoins, // ✅ Safety fallback
            totalOrders: userOrders.count,
            nextBigDealDate: Date().addingTimeInterval(86400 * 3)
        )
    }
}
