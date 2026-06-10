import Foundation

// ============================================================
// APIConfig.swift — VSN Home Centralized API Configuration
// ============================================================
// Currently configured for localhost development
// Update baseURL when hosting on college server
// ============================================================

struct APIConfig {

    // ── Base URL ──────────────────────────────────────────────
    // Change this URL when deploying to production college server
    static let baseURL = "http://localhost/vsn_grocery/"

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
    static let getSupport = baseURL + "get_support.php"

    // ── Razorpay ──────────────────────────────────────────────
    static var razorpayKeyID: String {
        get { UserDefaults.standard.string(forKey: "razorpay_key_id") ?? "rzp_test_Shak5FKtyKOOyF" }
        set { UserDefaults.standard.set(newValue, forKey: "razorpay_key_id") }
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
                    // Debug: print raw response
                    print("❌ JSON Decode Error: \(error)")
                    print("📦 Raw Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(error))
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
            completion(.failure(URLError(.badURL)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.timeoutInterval = 30
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
                    print("❌ JSON Decode Error: \(error)")
                    print("📦 Raw Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
