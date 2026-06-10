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
    static let background = Color(UIColor.systemGroupedBackground) // Light gray
    static let surface = Color(UIColor.secondarySystemGroupedBackground) // White
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

// MARK: - Market Trend Model
struct TrendItem: Identifiable, Hashable {
    var id = UUID()
    let label: String
    let value: String
    let color: Color
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
    let completed_referrals: Int?
    let pending_referrals: Int?
    let total_earned: Int
    let recent_referrals: [RecentReferral]
}

struct RecentReferral: Codable, Identifiable {
    var id: String { referee_email }
    let referee_email: String
    let name: String
    let reward_amount: Int
    let status: String?
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
    case tamil = "Tamil (தமிழ்)"
    
    var id: String { self.rawValue }
}

// MARK: - UI Localization Helper
struct AppText {
    static func get(_ key: String, lang: AppLanguage) -> String {
        let translations: [String: [AppLanguage: String]] = [
            // Profile Strings
            "hello": [.english: "HELLO", .hindi: "नमस्ते", .telugu: "నమస్కారం", .tamil: "வணக்கம்"],
            "vsn_home": [.english: "V.S.N. HOME", .hindi: "वी.एस.एन. होम", .telugu: "వి.ఎస్.ఎన్. హోమ్", .tamil: "வி.எஸ்.என். ஹோம்"],
            "hub_location": [.english: "Vijayawada Hub", .hindi: "विजयवाड़ा हब", .telugu: "విజయవాడ హబ్", .tamil: "விஜயவாடா ஹப்"],
            "profile_title": [.english: "Profile", .hindi: "प्रोफ़ाइल", .telugu: "ప్రొఫైల్", .tamil: "சுயவிவரம்"],
            "my_business": [.english: "My Business", .hindi: "मेरा व्यवसाय", .telugu: "నా వ్యాపారం", .tamil: "எனது தொழில்"],
            "business_wallet": [.english: "Business Wallet", .hindi: "व्यवसाय वॉलेट", .telugu: "వ్యాపార వాలెట్", .tamil: "தொழில் பணப்பை"],
            "loyalty_coins": [.english: "Loyalty Coins", .hindi: "लॉयल्टी सिक्के", .telugu: "లాయల్టీ నాణాలు", .tamil: "விசுவாச நாணயங்கள்"],
            "my_orders": [.english: "My Orders", .hindi: "मेरे आदेश", .telugu: "నా ఆర్డర్లు", .tamil: "எனது ஆர்டர்கள்"],
            "my_addresses": [.english: "My Addresses", .hindi: "मेरे पते", .telugu: "నా చిరునామాలు", .tamil: "எனது முகவரிகள்"],
            "settings": [.english: "Settings", .hindi: "सेटिंग्स", .telugu: "సెట్టింగులు", .tamil: "அமைப்புகள்"],
            "fav_language": [.english: "Language", .hindi: "भाषा", .telugu: "భాష", .tamil: "மொழி"],
            "support": [.english: "Support", .hindi: "सहायता", .telugu: "మద్దతు", .tamil: "ஆதரவு"],
            "call_manager": [.english: "Call Manager", .hindi: "मैनेजर को कॉल करें", .telugu: "మేనేజర్‌కి కాల్ చేయండి", .tamil: "மேலாளரை அழைக்கவும்"],
            "chat_whatsapp": [.english: "Chat on WhatsApp", .hindi: "व्हाट्सएप पर चैट करें", .telugu: "వాట్సాప్‌లో చాట్ చేయండి", .tamil: "வாட்ஸ்அப்பில் அரட்டையடிக்கவும்"],
            "logout": [.english: "Logout", .hindi: "लॉगआउट", .telugu: "లాగ్ అవుట్", .tamil: "வெளியேறு"],
            
            // Tab Strings
            "tab_wholesale": [.english: "Wholesale", .hindi: "थोक", .telugu: "టోకు", .tamil: "மொத்த விற்பனை"],
            "tab_deals": [.english: "Bulk Deals", .hindi: "बल्क डील्स", .telugu: "బల్క్ డీల్స్", .tamil: "மொத்த ஒப்பந்தங்கள்"],
            "tab_cart": [.english: "Cart", .hindi: "कार्ट", .telugu: "కార్ట్", .tamil: "கூடை"],
            "tab_insights": [.english: "Insights", .hindi: "इनसाइट्स", .telugu: "అంతర్దృష్టులు", .tamil: "நுண்ணறிவு"],
            "tab_stock": [.english: "Stock", .hindi: "स्टॉक", .telugu: "స్టాక్", .tamil: "சரக்கு"],
            "tab_orders": [.english: "Orders", .hindi: "आदेश", .telugu: "ఆర్డర్లు", .tamil: "ஆர்டர்கள்"],
            "tab_partners": [.english: "Partners", .hindi: "साझेदार", .telugu: "భాగస్వాములు", .tamil: "பங்காளிகள்"],
            "tab_alerts": [.english: "Alerts", .hindi: "अलर्ट", .telugu: "హెచ్చరికలు", .tamil: "எச்சரிக்கைகள்"],
            
            // Category Strings
            "cat_staples": [.english: "Staples", .hindi: "स्टेपल्स", .telugu: "స్టేపుల్స్", .tamil: "ஸ்டேபிள்ஸ்"],
            "cat_oil": [.english: "Oil & Ghee", .hindi: "तेल और घी", .telugu: "నూనె & నెయ్యి", .tamil: "எண்ணெய் & நெய்"],
            "cat_snacks": [.english: "Snacks", .hindi: "स्नैक्स", .telugu: "స్నాక్స్", .tamil: "தின்பண்டங்கள்"],
            "cat_cleaning": [.english: "Cleaning", .hindi: "सफाई", .telugu: "శుభ్రపరచడం", .tamil: "சுத்தம்"],
            "cat_dairy": [.english: "Dairy", .hindi: "डेयरी", .telugu: "పాడి", .tamil: "பால் பொருட்கள்"],
            
            // Home Strings
            "search_placeholder": [.english: "Search items...", .hindi: "सामान खोजें...", .telugu: "వస్తువుల కోసం వెతకండి...", .tamil: "பொருட்களைத் தேடுங்கள்..."],
            "live_trends": [.english: "LIVE TRENDS", .hindi: "लाइव ट्रेंड्स", .telugu: "లైవ్ ట్రెండ్స్", .tamil: "நேரடி போக்குகள்"],
            "all_category": [.english: "All", .hindi: "सब", .telugu: "అన్నీ", .tamil: "அனைத்தும்"],
            "trending_now": [.english: "Trending Now", .hindi: "अभी ट्रेंडिंग", .telugu: "ప్రస్తుతం ట్రెండింగ్‌", .tamil: "இப்போது டிரெண்டிங்"],
            "all_items": [.english: "All Items", .hindi: "सभी सामान", .telugu: "అన్ని వస్తువులు", .tamil: "அனைத்து பொருட்கள்"],
            "out_of_stock_only": [.english: "Out of Stock Only", .hindi: "केवल स्टॉक से बाहर", .telugu: "స్టాక్ లేనివి మాత్రమే", .tamil: "கையிருப்பில் இல்லாதவை மட்டும்"],
            "price_low_high": [.english: "Price: Low to High", .hindi: "कीमत: कम से अधिक", .telugu: "ధర: తక్కువ నుండి ఎక్కువ", .tamil: "விலை: குறைந்ததிலிருந்து அதிகமானது"],
            "price_high_low": [.english: "Price: High to Low", .hindi: "कीमत: अधिक से कम", .telugu: "ధర: ఎక్కువ నుండి తక్కువ", .tamil: "விலை: அதிகபட்சத்திலிருந்து குறைந்தது"],
            "reset_filters": [.english: "Reset Filters", .hindi: "फ़िल्टर रीसेट करें", .telugu: "ఫిల్టర్లను రీసెట్ చేయండి", .tamil: "வடிகட்டிகளை மீட்டமைக்கவும்"],
            
            // Common Actions
            "add_to_cart": [.english: "Add to Cart", .hindi: "कार्ट में जोड़ें", .telugu: "కార్టకు జోడించు", .tamil: "கூடைக்கு சேர்க்கவும்"],
            "sign_in": [.english: "Sign In", .hindi: "साइन इन करें", .telugu: "సైన్ ఇన్", .tamil: "உள்நுழைக"],
            "sign_up": [.english: "Sign Up", .hindi: "साइन अप करें", .telugu: "సైన్ అప్", .tamil: "பதிவு செய்க"],
            
            // Cart & Order
            "order_inventory": [.english: "Order Inventory", .hindi: "ऑर्डर इन्वेंटरी", .telugu: "ఆర్డర్ ఇన్‌వెంటరీ", .tamil: "ஆர்டர் சரக்கு"],
            "clear_all": [.english: "Clear All", .hindi: "सभी हटाएं", .telugu: "అన్నీ క్లియర్ చేయండి", .tamil: "அனைத்தையும் அழிக்கவும்"],
            "checkout": [.english: "Proceed to Checkout", .hindi: "चेकआउट के लिए आगे बढ़ें", .telugu: "చెక్‌అవుట్‌కు వెళ్లండి", .tamil: "பரிவர்த்தனைக்கு செல்லவும்"],
            "order_placed": [.english: "Order Placed", .hindi: "ऑर्डर प्राप्त", .telugu: "ఆర్డర్ ఆర్డర్ చేయబడింది", .tamil: "ஆர்டர் வைக்கப்பட்டது"],
            "use_coins": [.english: "Use Loyalty Coins", .hindi: "लॉयल्टी सिक्कों का उपयोग करें", .telugu: "లాయల్టీ నాణేలను ఉపయోగించండి", .tamil: "விசுவாச நாணயங்களைப் பயன்படுத்துங்கள்"],
            "coins_available": [.english: "You have %d coins available", .hindi: "आपके पास %d सिक्के उपलब्ध हैं", .telugu: "మీ దగ్గర %d నాణేలు అందుబాటులో ఉన్నాయి", .tamil: "உங்களிடம் %d நாணயங்கள் உள்ளன"],
            "worth": [.english: "Worth", .hindi: "कीमत", .telugu: "విలువ", .tamil: "மதிப்பு"],
            
            // Product Details
            "product_details": [.english: "Product Details", .hindi: "उत्पाद विवरण", .telugu: "ఉత్పత్తి వివరాలు", .tamil: "பொருளின் விபரம்"],
            "min_order_qty": [.english: "Min. Order Qty", .hindi: "न्यूनतम मात्रा", .telugu: "కనిష్ట ఆర్డర్ పరిమాణం", .tamil: "குறைந்தபட்ச ஆர்டர் அளவு"],
            "category": [.english: "Category", .hindi: "श्रेणी", .telugu: "వర్గం", .tamil: "பிரிவு"],
            "net_quantity": [.english: "Net Quantity", .hindi: "शुद्ध मात्रा", .telugu: "నికర పరిమాణం", .tamil: "நிகர அளவு"],
            "save_label": [.english: "SAVE", .hindi: "बचत", .telugu: "పొదుపు", .tamil: "சேமிப்பு"],
            "no_image": [.english: "No Image", .hindi: "कोई छवि नहीं", .telugu: "చిత్రం లేదు", .tamil: "படம் இல்லை"],
            "off_label": [.english: "OFF", .hindi: "छूट", .telugu: "తగ్గింపు", .tamil: "தள்ளுபடி"],
            "out_of_stock": [.english: "Out of Stock", .hindi: "स्टॉक से बाहर", .telugu: "స్టాక్‌లో లేనిది", .tamil: "பங்கிலிருந்து வெளியே"],
            
            // Admin UI
            "admin_portal": [.english: "Admin Portal", .hindi: "प्रशासक पोर्टल", .telugu: "కేం ఫ్రంటెండ్", .tamil: "நிர்வாக போர்టல்"],
            "add_product": [.english: "Add Product", .hindi: "उत्पाद जोड़ें", .telugu: "ఉత్పత్తిని జోడించండి", .tamil: "பொருள் சேர்க்கவும்"],
            "manage_users": [.english: "Manage Users", .hindi: "उपयोगकर्ताओं का प्रबंधन", .telugu: "వినియోగదారులను నిర్వహించండి", .tamil: "பயனர்களை நிர்வகித்தல்"],
            
            // Error Messages  
            "error_network": [.english: "Network error. Please check your connection.", .hindi: "नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।", .telugu: "నెట్‌వర్క్ ఎర్రర్. మీ కనెక్షన్ తనిఖీ చేయండి.", .tamil: "நெட்வொர்க் பிழை. உங்கள் இணைப்பை சரிபார்க்கவும்."],
            "error_invalid_input": [.english: "Invalid input. Please check your data.", .hindi: "अमान्य इनपुट। कृपया अपना डेटा जांचें।", .telugu: "చెల్లని ఇన్‌పుట్. దయచేసి మీ డేటా తనిఖీ చేయండి.", .tamil: "செல்லுபடியாகாத உள்ளீடு. உங்கள் தரவை சரிபார்க்கவும்."]
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
    let localizedNames: [String: String]? // Changed to String key for resilience
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
    
    init(
        id: String = UUID().uuidString,
        name: String,
        localizedNames: [String: String]? = nil,
        retailPrice: Double,
        wholesalePrice: Double,
        costPrice: Double? = nil,
        image: String,
        details: GroceryProductDetails? = nil,
        minOrderQty: Int? = nil,
        isTrending: Bool = false,
        rating: Double = 0.0,
        reviewCount: Int = 0,
        stockStatus: StockStatus = .inStock,
        coinOffer: CoinOffer? = nil
    ) {
        self.id = id
        self.name = name
        self.localizedNames = localizedNames
        self.retailPrice = retailPrice
        self.wholesalePrice = wholesalePrice
        self.costPrice = costPrice
        self.image = image
        self.details = details
        self.minOrderQty = minOrderQty
        self.isTrending = isTrending
        self.rating = rating
        self.reviewCount = reviewCount
        self.stockStatus = stockStatus
        self.coinOffer = coinOffer
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, localizedNames, retailPrice, wholesalePrice, costPrice, image, details, minOrderQty, isTrending, rating, reviewCount, stockStatus, coinOffer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Robust localizedNames decoding (handles both Dictionary and interleaved Array)
        if let dict = try? container.decode([String: String].self, forKey: .localizedNames) {
            localizedNames = dict
        } else if let arr = try? container.decode([String].self, forKey: .localizedNames) {
            var dict: [String: String] = [:]
            for i in stride(from: 0, to: arr.count - 1, by: 2) {
                dict[arr[i]] = arr[i+1]
            }
            localizedNames = dict
        } else {
            localizedNames = nil
        }
        
        retailPrice = try container.decode(Double.self, forKey: .retailPrice)
        wholesalePrice = try container.decode(Double.self, forKey: .wholesalePrice)
        costPrice = try container.decodeIfPresent(Double.self, forKey: .costPrice)
        image = try container.decode(String.self, forKey: .image)
        details = try container.decodeIfPresent(GroceryProductDetails.self, forKey: .details)
        minOrderQty = try container.decodeIfPresent(Int.self, forKey: .minOrderQty)
        isTrending = (try? container.decode(Bool.self, forKey: .isTrending)) ?? ((try? container.decode(Int.self, forKey: .isTrending)) == 1)
        rating = (try? container.decode(Double.self, forKey: .rating)) ?? 0.0
        reviewCount = (try? container.decode(Int.self, forKey: .reviewCount)) ?? 0
        stockStatus = (try? container.decode(StockStatus.self, forKey: .stockStatus)) ?? .inStock
        coinOffer = try? container.decodeIfPresent(CoinOffer.self, forKey: .coinOffer)
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
        return "₹" + (NumberFormatter.indian.string(from: NSNumber(value: retailPrice)) ?? "0")
    }
    
    var formattedWholesalePrice: String {
        return "₹" + (NumberFormatter.indian.string(from: NSNumber(value: wholesalePrice)) ?? "0")
    }
    
    // Get localized name based on preference
    func localizedName(for language: AppLanguage) -> String {
        return localizedNames?[language.rawValue] ?? name
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - Order Models
struct Order: Identifiable, Codable {
    var id: String
    let date: Date
    let items: [GroceryCartItem]?
    let total: Double
    var status: OrderStatus 
    var paymentStatus: PaymentStatus = .pending // Added payment status
    var paymentMethod: PaymentMethod = .cod // Added payment method
    let address: String? 
    let userEmail: String 
    var customDeliveryDate: Date? 
    
    // GST Details
    var requiresGSTBill: Bool? = false
    var businessName: String?
    var gstNumber: String?
    
    // Discount Tracking
    var discountAmount: Double = 0
    var deliveryCharge: Double = 0
    var appliedOfferTitle: String?
    var coinsEarned: Int? = 0 
    var coinsUsed: Int? = 0
    var coinDiscount: Double? = 0
    
    var totalProfit: Double {
        (items ?? []).reduce(0) { $0 + ($1.product.unitProfit * Double($1.quantity)) }
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
        case id, date, items, total, status, paymentStatus, paymentMethod, address, userEmail, customDeliveryDate, requiresGSTBill, businessName, gstNumber, discountAmount, deliveryCharge, appliedOfferTitle, coinsEarned, coinsUsed, coinDiscount
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
    let data: T?
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

// MARK: - Failable Codable Wrapper
struct FailableDecodable<Base: Codable>: Codable {
    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.base = try? container.decode(Base.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(base)
    }
}
