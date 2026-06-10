import SwiftUI
import Combine

// MARK: - Design System
struct AppColors {
    // Primary Palette (Trust & Professionalism - Deep Blue)
    static let primary = Color(red: 0.05, green: 0.45, blue: 0.85) // Trust Blue
    static let primaryLight = Color(red: 0.35, green: 0.65, blue: 0.95)
    static let primaryDark = Color(red: 0.02, green: 0.25, blue: 0.60)
    static let primaryText = Color.white
    
    // Secondary Palette (Growth & Savings - Vibrant Green)
    static let secondary = Color(red: 0.0, green: 0.65, blue: 0.40)
    static let secondaryLight = Color(red: 0.2, green: 0.8, blue: 0.55)
    
    // Modern UI Tokens
    static let accent = Color(red: 0.95, green: 0.45, blue: 0.20) // Energetic Orange
    static let glass = Color(UIColor.systemBackground).opacity(0.8)
    static let glassBorder = Color(UIColor.separator)
    
    // Status Colors
    static let success = Color(red: 0.15, green: 0.70, blue: 0.35)
    static let warning = Color(red: 1.0, green: 0.75, blue: 0.10)
    static let error = Color(red: 0.90, green: 0.25, blue: 0.25)
    static let info = Color(red: 0.10, green: 0.55, blue: 0.95)
    
    // Neutral Palette (Clean B2B Native Adaptive UI)
    static let background = Color(UIColor.systemGroupedBackground) // Light gray in light mode, dark in dark mode
    static let backgroundLight = Color(UIColor.secondarySystemGroupedBackground)
    static let surface = Color(UIColor.tertiarySystemGroupedBackground)
    static let surfaceLight = Color(UIColor.systemBackground).opacity(0.85) // Glassmorphic transparency
    
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    
    // Gradients (Clean corporate feel)
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [primary, Color(red: 0.1, green: 0.5, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var secondaryGradient: LinearGradient {
        LinearGradient(colors: [secondary, secondaryLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var goldGradient: LinearGradient {
        LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.2), Color(red: 1.0, green: 0.65, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(colors: [primary, primaryLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    static var darkSurfaceGradient: LinearGradient {
        LinearGradient(colors: [surfaceLight, surface], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Modern UI Modifiers
struct ModernCard: ViewModifier {
    var backgroundColor: Color = AppColors.surfaceLight
    func body(content: Content) -> some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

struct Glassmorphism: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.glassBorder.opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func modernCard(backgroundColor: Color = AppColors.surfaceLight) -> some View {
        self.modifier(ModernCard(backgroundColor: backgroundColor))
    }
    func glassMorphic() -> some View {
        self.modifier(Glassmorphism())
    }
}

// MARK: - External Features Models
struct BusinessAnalytics: Codable {
    var totalSavings: Double
    var orderVelocity: Double // orders per month
    var growthPercentage: Double
    var walletCoins: Int // Added coins tracking
    var totalOrders: Int // Added total orders count
    var nextBigDealDate: Date?
    
    static let mock = BusinessAnalytics(
        totalSavings: 12500.50,
        orderVelocity: 14.5,
        growthPercentage: 22.4,
        walletCoins: 1240,
        totalOrders: 42,
        nextBigDealDate: Date().addingTimeInterval(86400 * 3)
    )
    
    static let empty = BusinessAnalytics(
        totalSavings: 0,
        orderVelocity: 0,
        growthPercentage: 0,
        walletCoins: 0,
        totalOrders: 0,
        nextBigDealDate: nil
    )
}

// MARK: - Admin Analytics Models
struct AdminAnalytics: Codable {
    struct DataPoint: Codable, Identifiable {
        var id: String { label }
        let label: String
        let value: Double
    }
    
    struct KPI: Codable {
        let totalOrders: Int
        let totalRevenue: Double
        let totalDiscounts: Double
        let totalCoins: Int
        let uniqueCustomers: Int
    }
    
    let revenue: [DataPoint]
    let products: [DataPoint]
    let statuses: [DataPoint]
    let kpi: KPI
}

// MARK: - Referral Models
struct ReferralStats: Codable {
    let referral_code: String
    let total_coins: Int
    let total_referrals: Int
    let total_earned: Int
    let recent_referrals: [RecentReferral]
}

struct RecentReferral: Codable, Identifiable {
    var id: String { referee_email }
    let referee_email: String
    let name: String
    let reward_amount: Int
    let created_at: String
}

// MARK: - Haptic Feedback Manager
struct HapticManager {
    static let shared = HapticManager()
    
    func trigger(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Premium UI Components
struct PremiumShadow: ViewModifier {
    var radius: CGFloat = 8
    var y: CGFloat = 4
    var opacity: Double = 0.04 // Softer for minimal design
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: y)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

struct GlowEffect: ViewModifier {
    var color: Color
    var radius: CGFloat = 8
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.2), radius: radius)
    }
}

extension View {
    func premiumCard(radius: CGFloat = 16) -> some View {
        self.modifier(PremiumShadow())
            .background(AppColors.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
    
    func glow(color: Color = AppColors.primary, radius: CGFloat = 8) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }
    
    func glassmorphism(opacity: Double = 0.8) -> some View {
        self
            .background(
                BlurView(style: .systemThinMaterial)
                    .opacity(opacity)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    
    func atmosphericBackground() -> some View {
        self.background(
            ZStack {
                AppColors.background.ignoresSafeArea()
                // Extremely subtle gradients for a clean modern vibe instead of heavy neon
                RadialGradient(
                    colors: [AppColors.primary.opacity(0.02), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
            }
        )
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "English"
    case hindi = "Hindi (हिन्दी)"
    case telugu = "Telugu (తెలుగు)"
    case kannada = "Kannada (ಕನ್ನಡ)"
    case tamil = "Tamil (தமிழ்)"
    case punjabi = "Punjabi (ਪੰਜਾਬੀ)"
    case marathi = "Marathi (मराठी)"
    
    var id: String { self.rawValue }
}

// MARK: - UI Localization Helper
struct AppText {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let translations: [String: [AppLanguage: String]] = [
            // Profile Strings
            "profile_title": [.english: "Profile", .hindi: "प्रोफ़ाइल", .telugu: "ప్రొఫైల్", .kannada: "ಪ್ರೊಫೈಲ್", .tamil: "சுயவிவரம்", .punjabi: "ਪ੍ਰੋਫਾਈਲ", .marathi: "प्रोफाइल"],
            "my_business": [.english: "My Business", .hindi: "मेरा व्यवसाय", .telugu: "నా వ్యాపారం", .kannada: "ನನ್ನ ವ್ಯವಹಾರ", .tamil: "எனது தொழில்", .punjabi: "ਮੇਰਾ ਕਾਰੋਬਾਰ", .marathi: "माझा व्यवसाय"],
            "business_wallet": [.english: "Business Wallet", .hindi: "व्यवसाय वॉलेट", .telugu: "వ్యాపార వాలెట్", .kannada: "ವ್ಯವಹಾರ ವ್ಯಾಲೆಟ್", .tamil: "தொழில் பணப்பை", .punjabi: "ਕਾਰੋਬਾਰੀ ਵਾਲਿਟ", .marathi: "व्यवसाय वॉलेट"],
            "loyalty_coins": [.english: "Loyalty Coins", .hindi: "लॉयल्टी सिक्के", .telugu: "లాయల్టీ నాణాలు", .kannada: "ನಿಷ್ಠಾವಂತ ನಾಣ್ಯಗಳು", .tamil: "விசுவாச நாணயங்கள்", .punjabi: "ਵਫ਼ਾਦਾਰੀ ਸਿੱਕੇ", .marathi: "निष्ठा नाणी"],
            "my_orders": [.english: "My Orders", .hindi: "मेरे आदेश", .telugu: "నా ఆర్డర్లు", .kannada: "ನನ್ನ ಆದೇಶಗಳು", .tamil: "எனது ஆர்டர்கள்", .punjabi: "ਮੇਰੇ ਆਰਡਰ", .marathi: "माझे आदेश"],
            "my_addresses": [.english: "My Addresses", .hindi: "मेरे पते", .telugu: "నా చిరునామాలు", .kannada: "ನನ್ನ ವಿಳಾಸಗಳು", .tamil: "எனது முகவரிகள்", .punjabi: "ਮੇਰੇ ਪਤੇ", .marathi: "माझे पत्ते"],
            "settings": [.english: "Settings", .hindi: "सेटिंग्स", .telugu: "సెట్టింగులు", .kannada: "ಸೆಟ್ಟಿಂಗ್ಗಳು", .tamil: "அமைப்புகள்", .punjabi: "ਸੈਟਿੰਗਾਂ", .marathi: "सेटिंग्ज"],
            "fav_language": [.english: "Language", .hindi: "भाषा", .telugu: "భాష", .kannada: "భాషె", .tamil: "மொழி", .punjabi: "ਭਾਸ਼ਾ", .marathi: "भाषा"],
            "support": [.english: "Support", .hindi: "सहायता", .telugu: "మద్దతు", .kannada: "ಬೆಂಬಲ", .tamil: "ஆதரவு", .punjabi: "ਸਹਾਇਤਾ", .marathi: "समर्थन"],
            "call_manager": [.english: "Call Manager", .hindi: "मैनेजर को कॉल करें", .telugu: "మేనేజర్‌కి కాల్ చేయండి", .kannada: "ಮ್ಯಾನೇಜರ್‌ಗೆ ಕರೆ ಮಾಡಿ", .tamil: "மேலாளரை அழைக்கவும்", .punjabi: "ਮੈਨੇਜਰ ਨੂੰ ਕਾਲ ਕਰੋ", .marathi: "व्यवस्थापकाला कॉल करा"],
            "chat_whatsapp": [.english: "Chat on WhatsApp", .hindi: "व्हाट्सएप पर चैट करें", .telugu: "వాట్సాప్‌లో చాట్ చేయండి", .kannada: "ವಾట్సాప్‌ನಲ್ಲಿ ਚಾಟ್ ಮಾಡಿ", .tamil: "வாட்ஸ்அப்பில் அரட்டையடிக்கவும்", .punjabi: "ਵਟਸਐਪ 'ਤੇ ਚੈਟ ਕਰੋ", .marathi: "व्हॉट्सॲपवर चॅट करा"],
            "logout": [.english: "Logout", .hindi: "लॉगआउट", .telugu: "లాగ్ అవుట్", .kannada: "ಲಾಗ್ ಔਟ", .tamil: "வெளியேறு", .punjabi: "ਲੌਗਆਉਟ", .marathi: "लॉगआउट"],
            
            // Tab Strings
            "tab_wholesale": [.english: "Wholesale", .hindi: "थोक", .telugu: "టోకు", .kannada: "ಸಗಟು", .tamil: "மொத்த விற்பனை", .punjabi: "ਥੋਕ", .marathi: "घाऊक"],
            "tab_deals": [.english: "Bulk Deals", .hindi: "बल्क डील्स", .telugu: "బల్క్ డీల్స్", .kannada: "ಬల్క్ ਡੀಲ್స్", .tamil: "மொத்த ஒப்பந்தங்கள்", .punjabi: "ਬਲਕ ਡੀਲਜ਼", .marathi: "मोठ्या सौदे"],
            "tab_cart": [.english: "Cart", .hindi: "कार्ट", .telugu: "కార్ట్", .kannada: "ಕಾರ್ಟ್", .tamil: "கூடை", .punjabi: "ਕਾਰਟ", .marathi: "कार्ट"],
            
            // Home Strings
            "search_placeholder": [.english: "Search items...", .hindi: "सामान खोजें...", .telugu: "వస్తువుల కోసం వెతకండి...", .kannada: "ವಸ್ತುಗಳನ್ನು ಹುಡುಕಿ...", .tamil: "பொருட்களைத் தேடுங்கள்...", .punjabi: "ਵਸਤੂਆਂ ਦੀ ਖੋਜ ਕਰੋ...", .marathi: "वस्तू शोधा..."],
            "all_category": [.english: "All", .hindi: "सब", .telugu: "అన్నీ", .kannada: "ಎಲ್ಲಾ", .tamil: "அனைத்தும்", .punjabi: "ਸਾਰੇ", .marathi: "सर्व"],
            "trending_now": [.english: "Trending Now", .hindi: "अभी ट्रेंडिंग", .telugu: "ప్రస్తుతం ట్రెండింగ్‌", .kannada: "ಈಗ ట్రెండింగ్", .tamil: "இப்போது டிரெண்டிங்", .punjabi: "ਹੁਣ ਟ੍ਰੈਂਡਿੰਗ", .marathi: "आता ट्रेंडिंग"],
            "all_items": [.english: "All Items", .hindi: "सभी सामान", .telugu: "అన్ని వస్తువులు", .kannada: "ಎಲ್ಲಾ ವಸ್ತುಗಳು", .tamil: "அனைத்து பொருட்கள்", .punjabi: "ਸਾਰੀਆਂ ਵਸਤੂਆਂ", .marathi: "सर्व वस्तू"]
        ]
        
        return translations[key]?[lang] ?? key
    }
}

// MARK: - Product Models
struct GroceryProductDetails: Identifiable, Hashable, Codable {
    var id = UUID()
    let description: String?
    let category: ProductCategory
    let brand: String?
    let netQuantity: String?
    
    enum CodingKeys: String, CodingKey {
        case description, category, brand, netQuantity
    }
}

enum ProductCategory: String, CaseIterable, Hashable, Codable {
    case all = "All"
    case staples = "Staples"
    case oil = "Oil & Ghee"
    case snacks = "Snacks"
    case cleaning = "Cleaning"
    case dairy = "Dairy"
}

enum StockStatus: String, CaseIterable, Hashable, Codable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    
    var color: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .orange
        case .outOfStock: return .red
        }
    }
}

struct CoinOffer: Hashable, Codable {
    let thresholdQuantity: Int
    let rewardCoins: Int
    let description: String
}

struct GroceryProduct: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let localizedNames: [AppLanguage: String]? // Translations
    let retailPrice: Double
    let wholesalePrice: Double
    let costPrice: Double? // Added cost price for P&L
    let image: String
    let details: GroceryProductDetails?
    let minOrderQty: Int?
    var isTrending: Bool = false
    var rating: Double = 0.0
    var reviewCount: Int = 0
    var stockStatus: StockStatus = .inStock
    var coinOffer: CoinOffer? // Added coin offer per item
    
    var isOutOfStock: Bool { stockStatus == .outOfStock }
    
    enum CodingKeys: String, CodingKey {
        case id, name, localizedNames, retailPrice, wholesalePrice, costPrice, image, details, minOrderQty, isTrending, rating, reviewCount, stockStatus, coinOffer
    }
    
    // Calculate savings for user
    var savings: Double {
        return retailPrice - wholesalePrice
    }
    
    // Calculate percentage discount
    var discountPercentage: Int {
        let discount = (retailPrice - wholesalePrice) / retailPrice * 100
        return Int(discount)
    }
    
    // Calculate profit for admin
    var unitProfit: Double {
        return wholesalePrice - (costPrice ?? 0)
    }
    
    // Formatting Helpers
    var formattedRetailPrice: String {
        return "₹" + NumberFormatter.indian.string(from: NSNumber(value: retailPrice))!
    }
    
    var formattedWholesalePrice: String {
        return "₹" + NumberFormatter.indian.string(from: NSNumber(value: wholesalePrice))!
    }
    
    // Get localized name based on preference
    func localizedName(for language: AppLanguage) -> String {
        return localizedNames?[language] ?? name
    }
}

struct GroceryCartItem: Identifiable, Codable {
    var id = UUID()
    let product: GroceryProduct
    var quantity: Int
    
    enum CodingKeys: String, CodingKey {
        case product, quantity
    }
}

enum OrderStatus: String, Codable {
    case pending = "Pending"
    case processing = "Processing"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"
    case cancelled = "Cancelled"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self).lowercased()
        switch status {
        case "pending": self = .pending
        case "processing": self = .processing
        case "outfordelivery", "out_for_delivery", "out for delivery": self = .outForDelivery
        case "delivered": self = .delivered
        case "cancelled": self = .cancelled
        default: self = .pending
        }
    }
}

enum PaymentStatus: String, Codable {
    case pending = "Pending"
    case paid = "Paid"
    case failed = "Failed"
    case refunded = "Refunded"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self).lowercased()
        switch status {
        case "pending": self = .pending
        case "paid", "success": self = .paid
        case "failed": self = .failed
        case "refunded": self = .refunded
        default: self = .pending
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cod = "Cash on Delivery"
    case upi = "UPI Transfer"
    case bank = "Bank Transfer"
    case credits = "Store Credits"
    case razorpay = "Razorpay (Online Payment)"
    case razorpayDummy = "Razorpay (Test Mode)"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let method = try container.decode(String.self).lowercased()
        if method.contains("cod") || method.contains("cash") { self = .cod }
        else if method.contains("upi") { self = .upi }
        else if method.contains("bank") { self = .bank }
        else if method.contains("credit") { self = .credits }
        else if method.contains("razorpay") { self = .razorpay }
        else { self = .cod }
    }
}

// MARK: - Order Models
struct Order: Identifiable, Codable {
    var id: String
    let date: Date
    let items: [GroceryCartItem]
    let total: Double
    var status: OrderStatus 
    var paymentStatus: PaymentStatus = .pending // Added payment status
    var paymentMethod: PaymentMethod = .cod // Added payment method
    let address: String 
    let userEmail: String 
    var customDeliveryDate: Date? 
    
    // GST Details
    var requiresGSTBill: Bool = false
    var businessName: String?
    var gstNumber: String?
    
    // Discount Tracking
    var discountAmount: Double = 0
    var deliveryCharge: Double = 0
    var appliedOfferTitle: String?
    var coinsEarned: Int = 0 // Added coins tracking in order
    
    var totalProfit: Double {
        items.reduce(0) { $0 + ($1.product.unitProfit * Double($1.quantity)) }
    }
    
    // Calculate estimated delivery date based on status or custom date
    var estimatedDeliveryDate: Date {
        // If admin set a custom date, use that
        if let customDate = customDeliveryDate {
            return customDate
        }
        
        // Otherwise calculate based on status (default 2-3 days)
        let calendar = Calendar.current
        switch status {
        case .pending:
            return calendar.date(byAdding: .day, value: 3, to: date) ?? date // 2-3 days
        case .processing:
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date // 2 days
        case .outForDelivery:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date // Next day
        case .delivered:
            return date // Already delivered
        case .cancelled:
            return date // N/A
        }
    }
    
    // Format delivery date for display
    var deliveryDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch status {
        case .delivered:
            return "Delivered on \(formatter.string(from: date))"
        case .cancelled:
            return "Order Cancelled"
        default:
            return "Expected by \(formatter.string(from: estimatedDeliveryDate))"
        }
    }
    enum CodingKeys: String, CodingKey {
        case id, date, items, total, status, paymentStatus, paymentMethod, address, userEmail, customDeliveryDate, requiresGSTBill, businessName, gstNumber, discountAmount, deliveryCharge, appliedOfferTitle, coinsEarned
    }
}

// MARK: - Bulk Offer Model
struct BulkOffer: Identifiable, Codable {
    var id: String = UUID().uuidString
    let title: String
    let description: String
    let minOrderValue: Double
    let discountPercentage: Double?
    let discountAmount: Double?
    
    var isFlat: Bool {
        discountAmount != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, minOrderValue, discountPercentage, discountAmount
    }
}




// MARK: - Notification Model
struct AppNotification: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    let title: String
    let message: String
    let date: Date
    var isRead: Bool = false
    let type: NotificationType
    var userEmail: String? = "all"
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, date, isRead, type, userEmail
    }
}

enum NotificationType: String, CaseIterable, Codable {
    case offer = "Offer"
    case order = "Order Update"
    case general = "General"
}

// MARK: - API Helpers
struct SimpleResponse: Codable {
    let status: String
    let message: String
}

struct APIResponse<T: Codable>: Codable {
    let status: String
    let data: T
    var message: String? = nil
}

struct AdminLoginResponse: Codable {
    let status: String
    let message: String
    let data: AdminData?
    
    struct AdminData: Codable {
        let email: String
        let upi_id: String?
    }
}

// MARK: - Formatters
extension NumberFormatter {
    static var indian: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter
    }
}
