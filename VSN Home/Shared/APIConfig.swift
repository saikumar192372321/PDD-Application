import Foundation

// ============================================================
// APIConfig.swift — VSN Home Centralized API Configuration
// ============================================================
// Currently configured for localhost development
// Update baseURL when hosting on college server
// ============================================================

struct APIConfig {

    // ── Base URL ──────────────────────────────────────────────
    // Priority: environment variable → build config constant → debug fallback
    // PRODUCTION: Set VSN_API_URL in Xcode Scheme → Run → Environment Variables
    // OR change the #else value below to your live server URL before App Store build.
    // Example: "https://yourserver.com/vsn_grocery/"
    static let baseURL: String = {
        if let envURL = ProcessInfo.processInfo.environment["VSN_API_URL"], !envURL.isEmpty {
            return envURL
        }
        #if DEBUG
        // Development: use your Mac's IP address (e.g. http://192.168.x.x/vsn_grocery/)
        // Run: ifconfig | grep 'inet ' to find your IP
        return "http://localhost/vsn_grocery/"
        #else
        // ⚠️ PRODUCTION: Replace with your live server URL before App Store submission
        return "https://YOUR_PRODUCTION_SERVER.com/vsn_grocery/"
        #endif
    }()

    // ── Auth ──────────────────────────────────────────────────
    static let register = baseURL + "register.php"
    static let login    = baseURL + "login.php"

    // ── Products ──────────────────────────────────────────────
    static let getProducts  = baseURL + "get_products.php"
    static let addProduct   = baseURL + "add_product.php"
    static let deleteProduct = baseURL + "delete_product.php"
    static let updateStock  = baseURL + "update_stock.php"

    // ── Orders ────────────────────────────────────────────────
    static let placeOrder       = baseURL + "place_order.php"
    static let getOrders        = baseURL + "get_orders.php"
    static let updateOrderStatus = baseURL + "update_order_status.php"

    // ── Offers ────────────────────────────────────────────────
    static let getOffers    = baseURL + "get_offers.php"
    static let addOffer     = baseURL + "add_offer.php"
    static let deleteOffer  = baseURL + "delete_offer.php"

    // ── Notifications ─────────────────────────────────────────
    static let getNotifications     = baseURL + "get_notifications.php"
    static let sendNotification     = baseURL + "send_notification.php"
    static let deleteNotification   = baseURL + "delete_notification.php"
    static let markNotificationsRead = baseURL + "mark_notifications_read.php"

    // ── Profile ───────────────────────────────────────────────
    static let getProfile = baseURL + "get_profile.php"

    // ── Password Reset ────────────────────────────────────────
    static let forgotPassword = baseURL + "forgot_password.php"
    static let resetPassword  = baseURL + "reset_password.php"

    // ── Admin ─────────────────────────────────────────────────
    static let adminLogin    = baseURL + "admin_login.php"
    static let adminAnalytics = baseURL + "admin_analytics.php"
    static let getUsers      = baseURL + "get_users.php"
    static let addAdmin      = baseURL + "add_admin.php"
    static let deleteAccount = baseURL + "delete_account.php"

    // ── Referrals ─────────────────────────────────────────────
    static let getReferralStats = baseURL + "get_referral_stats.php"

    // ── Support ───────────────────────────────────────────────
    static let getSupport = baseURL + "support.php"

    // ── Razorpay ──────────────────────────────────────────────
    // PRODUCTION KEY: Use KeychainManager for secure storage
    // Check environment variable, then Keychain, then fallback
    static var razorpayKeyID: String {
        get {
            if let envKey = ProcessInfo.processInfo.environment["RAZORPAY_KEY_ID"] {
                return envKey
            }
            if let keychainKey = try? KeychainManager.retrieve(key: "razorpay_key_id", type: String.self) {
                return keychainKey
            }
            // Fallback for development only
            #if DEBUG
            return "rzp_test_Shak5FKtyKOOyF"
            #else
            return "" // Production: must be set via environment or Keychain
            #endif
        }
        set { 
            try? KeychainManager.save(newValue, key: "razorpay_key_id")
        }
    }
    static let createRazorpayOrder = baseURL + "razorpay_order.php"

    // ── Health Check ──────────────────────────────────────────
    static let healthCheck = baseURL + "test.php"

    // ── Network Helper: POST JSON ──────────────────────────────
    /// Performs a POST request and decodes the response as Decodable T.
    static func post<T: Decodable>(
        to urlString: String,
        body: [String: Any],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 30
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else {
                    completion(.failure(URLError(.zeroByteResource))); return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    #if DEBUG
                    print("❌ JSON Decode Error: \(error)")
                    if let rawStr = String(data: data, encoding: .utf8) {
                        print("📦 Raw Response: \(rawStr)")
                    }
                    #endif
                    let nsError = NSError(domain: "APIConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server response. Please check your network connection and try again."])
                    completion(.failure(nsError))
                }
            }
        }.resume()
    }

    /// Performs a GET request and decodes the response.
    static func get<T: Decodable>(
        from urlString: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            let nsError = NSError(domain: "APIConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid server configuration. Please contact support."])
            completion(.failure(nsError))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 30
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = NSError(domain: "APIConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network connection failed. Please check your internet and try again."])
                    completion(.failure(nsError))
                    return
                }
                guard let data = data else {
                    let nsError = NSError(domain: "APIConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received from server."])
                    completion(.failure(nsError))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    #if DEBUG
                    print("❌ JSON Decode Error: \(error)")
                    if let rawStr = String(data: data, encoding: .utf8) {
                        print("📦 Raw Response: \(rawStr)")
                    }
                    #endif
                    let nsError = NSError(domain: "APIConfig", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse server response. Please try again."])
                    completion(.failure(nsError))
                }
            }
        }.resume()
    }
}
