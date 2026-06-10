import Foundation
import SwiftUI

struct MockData {
    static let products: [GroceryProduct] = [
        // MARK: - Staples
        GroceryProduct(
            name: "Basmati Rice (Premium)",
            localizedNames: [.english: "Basmati Rice (Premium)", .hindi: "बासमती चावल", .telugu: "బాస్మతీ బియ్యం"],
            retailPrice: 3200,
            wholesalePrice: 2850,
            costPrice: 2400,
            image: "leaf.fill",
            details: GroceryProductDetails(
                description: "Top-quality long-grain Basmati rice, aged for 2 years. Perfect for Biryani and Pulao.",
                category: .staples,
                brand: "VSN Gold",
                netQuantity: "25 Kg"
            ),
            minOrderQty: 1,
            isTrending: true,
            rating: 4.8,
            reviewCount: 1250,
            stockStatus: .inStock,
            coinOffer: CoinOffer(thresholdQuantity: 2, rewardCoins: 500, description: "Bulk Reward: 500 coins on 2+ bags")
        ),
        GroceryProduct(
            name: "Toor Dal (Premium)",
            localizedNames: [.english: "Toor Dal (Premium)", .hindi: "तूर दाल", .telugu: "కందిపప్పు"],
            retailPrice: 180,
            wholesalePrice: 155,
            costPrice: 130,
            image: "circle.grid.2x2.fill",
            details: GroceryProductDetails(
                description: "Premium quality unpolished toor dal, rich in protein and fiber.",
                category: .staples,
                brand: "VSN Fresh",
                netQuantity: "5 Kg Bag"
            ),
            minOrderQty: 10,
            rating: 4.5,
            reviewCount: 840,
            stockStatus: .inStock
        ),
        GroceryProduct(
            name: "Premium Wheat Atta",
            localizedNames: [.english: "Premium Wheat Atta", .hindi: "गेहूँ का आटा", .telugu: "గోధుమ పిండి"],
            retailPrice: 550,
            wholesalePrice: 480,
            costPrice: 400,
            image: "bag.fill",
            details: GroceryProductDetails(
                description: "100% Sharbati whole wheat flour. Soft rotis guaranteed.",
                category: .staples,
                brand: "VSN Pure",
                netQuantity: "10 Kg"
            ),
            minOrderQty: 5,
            isTrending: true,
            rating: 4.7,
            reviewCount: 2100,
            stockStatus: .inStock
        ),
        
        // MARK: - Oils & Ghee
        GroceryProduct(
            name: "Sunflower Oil",
            localizedNames: [.english: "Sunflower Oil", .hindi: "सूरजमुखी तेल", .telugu: "సన్ ఫ్లవర్ ఆయిల్"],
            retailPrice: 2100,
            wholesalePrice: 1850,
            costPrice: 1600,
            image: "drop.fill",
            details: GroceryProductDetails(
                description: "Refined sunflower oil, rich in Vitamin E. Ideal for healthy cooking.",
                category: .oil,
                brand: "SunPure",
                netQuantity: "15 L Tin"
            ),
            minOrderQty: 5,
            rating: 4.2,
            reviewCount: 560,
            stockStatus: .lowStock,
            coinOffer: CoinOffer(thresholdQuantity: 5, rewardCoins: 1000, description: "Oil Bonanza: 1000 coins on 5+ tins")
        ),
        GroceryProduct(
            name: "Pure Cow Ghee",
            localizedNames: [.english: "Pure Cow Ghee", .hindi: "शुद्ध गाय का घी", .telugu: "ఆవు నెయ్యి"],
            retailPrice: 650,
            wholesalePrice: 580,
            costPrice: 500,
            image: "flame.fill",
            details: GroceryProductDetails(
                description: "Traditional Bilona method cow ghee. Pure and aromatic.",
                category: .oil,
                brand: "VSN Pure",
                netQuantity: "1 Kg Jar"
            ),
            minOrderQty: 10,
            rating: 4.9,
            reviewCount: 3200,
            stockStatus: .inStock
        ),
        
        // MARK: - Snacks & Biscuits
        GroceryProduct(
            name: "Biscuits Assorted",
            localizedNames: [.english: "Biscuits Assorted", .hindi: "मिश्रित बिस्कुट", .telugu: "బిస్కెట్లు"],
            retailPrice: 220,
            wholesalePrice: 180,
            costPrice: 150,
            image: "square.grid.3x3.fill",
            details: GroceryProductDetails(
                description: "Variety pack of assorted cream and digestive biscuits.",
                category: .snacks,
                brand: "Britannia",
                netQuantity: "2 Kg Family Box"
            ),
            minOrderQty: 12,
            rating: 4.4,
            reviewCount: 450,
            stockStatus: .inStock
        ),
        GroceryProduct(
            name: "Massala Peanuts",
            localizedNames: [.english: "Massala Peanuts", .hindi: "मसाला मूंगफली", .telugu: "మసాలా వేరుశనగలు"],
            retailPrice: 120,
            wholesalePrice: 95,
            costPrice: 75,
            image: "mouth",
            details: GroceryProductDetails(
                description: "Crunchy spicy peanuts. Best tea-time snack.",
                category: .snacks,
                brand: "Haldirams",
                netQuantity: "500g Pack"
            ),
            minOrderQty: 24,
            rating: 4.3,
            reviewCount: 110,
            stockStatus: .inStock
        ),
        
        // MARK: - Cleaning
        GroceryProduct(
            name: "Dishwash Liquid",
            localizedNames: [.english: "Dishwash Liquid", .hindi: "डिशवॉश लिक्विड", .telugu: "డిష్ వాష్ లిక్విడ్"],
            retailPrice: 450,
            wholesalePrice: 380,
            costPrice: 320,
            image: "sparkles",
            details: GroceryProductDetails(
                description: "Tough on grease, gentle on hands. Concentrated formula.",
                category: .cleaning,
                brand: "Vim",
                netQuantity: "5 L Can"
            ),
            minOrderQty: 4,
            rating: 4.6,
            reviewCount: 920,
            stockStatus: .inStock
        ),
        GroceryProduct(
            name: "Detergent Powder",
            localizedNames: [.english: "Detergent Powder", .hindi: "डिटर्जेंट पाउडर", .telugu: "డిటర్జెంట్ పౌడర్"],
            retailPrice: 850,
            wholesalePrice: 720,
            costPrice: 600,
            image: "tshirt.fill",
            details: GroceryProductDetails(
                description: "Extra power wash for front load and top load machines.",
                category: .cleaning,
                brand: "Surf Excel",
                netQuantity: "10 Kg"
            ),
            minOrderQty: 2,
            rating: 4.8,
            reviewCount: 1500,
            stockStatus: .inStock
        )
    ]

    static let offers: [BulkOffer] = [
        BulkOffer(
            title: "Festive Rice Sale",
            description: "Get ₹200 off on every 25kg bag of Basmati Rice.",
            minOrderValue: 5000,
            discountPercentage: nil,
            discountAmount: 200
        ),
        BulkOffer(
            title: "Oil Bulk Deal",
            description: "10% discount on orders above ₹15,000 for all oils.",
            minOrderValue: 15000,
            discountPercentage: 0.1,
            discountAmount: nil
        ),
        BulkOffer(
            title: "Wholesale Welcome",
            description: "Flat ₹500 discount on your first order above ₹10,000.",
            minOrderValue: 10000,
            discountPercentage: nil,
            discountAmount: 500
        )
    ]

    // Orders are intentionally empty — real orders are fetched from
    // the server using the logged-in user's email. Never use mock
    // orders as a fallback; that would show another user's data.
    static let orders: [Order] = []
}

