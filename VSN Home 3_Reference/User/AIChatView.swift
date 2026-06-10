import SwiftUI
import Combine

struct Message: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isTyping = false
    
    private let botName = "VSN Business Consultant"
    var productStore: GroceryProductStore?
    
    // MARK: - Training Dataset (B2B Knowledge Bank)
    private let businessKnowledgeBase: [String: String] = [
        "retention": "Customer Retention Strategy: Implement a 'Bulk Loyalty' program. Offer your shop's customers a small discount when they buy 3+ units of staples. This mimics the VSN wholesale model and ensures they return to you for their monthly pantry needs.",
        "lean": "Lean Inventory Management: Follow the JIT (Just-In-Time) principle. Don't overstock slow-moving categories (like premium cleaning supplies). Instead, use VSN's 24-48h fulfillment for those and keep your capital 'liquid' for high-velocity items like Oils and Ghee.",
        "seasonal": "Seasonal Planning: Vijayawada regions see a 40% spike in Ghee and Staples during the wedding/festival season. We recommend increasing your 'Buffer Stock' by 2.5x at least 15 days before major local festivals to avoid stock-outs when prices peak.",
        "competitor": "Defeating Competition: If a nearby shop undercuts your prices on staples, focus on 'Value Bundling'. Pair a high-margin snack item with a low-margin staple. This keeps your average transaction value (ATV) high while remaining price-competitive.",
        "staffing": "Operational Efficiency: In a grocery business, 15% of losses come from 'Shrinkage' (damage/theft). Training your staff on FEFO (First-Expire-First-Out) stock rotation is the #1 way to protect your margins.",
        "digital": "Digital Expansion: Use WhatsApp Business to broadcast your VSN-procured 'Bulk Deals' to your local neighborhood. This creates an 'Active Demand' channel that doesn't rely on foot traffic alone."
    ]
    
    init(productStore: GroceryProductStore? = nil) {
        self.productStore = productStore
        messages.append(Message(content: "Welcome to the VSN Business Intelligence Hub. My training bank is loaded with Vijayawada market datasets and B2B growth models. How can we scale your profit today?", isUser: false))
    }
    
    func sendMessage(_ content: String) {
        let userMessage = Message(content: content, isUser: true)
        messages.append(userMessage)
        HapticManager.shared.trigger(.light)
        
        generateResponse(to: content)
    }
    
    private func generateResponse(to input: String) {
        isTyping = true
        let lowerInput = input.lowercased()
        
        // Simulating high-level strategic computation
        let complexityFactor = (lowerInput.contains("grow") || lowerInput.contains("strategy") || lowerInput.contains("analyze")) ? 3.0 : 1.2
        
        DispatchQueue.main.asyncAfter(deadline: .now() + complexityFactor) {
            var response: String = ""
            
            if let store = self.productStore {
                // 1. DYNAMIC CATEGORY/KEYWORD INTELLIGENCE
                let productKeywords: [String: String] = [
                    "rice": "Basmati Rice (Premium)",
                    "dal": "Toor Dal (Premium)",
                    "wheat": "Premium Wheat Atta",
                    "atta": "Premium Wheat Atta",
                    "oil": "Sunflower Oil",
                    "ghee": "Pure Cow Ghee",
                    "peanut": "Massala Peanuts",
                    "biscuit": "Biscuits Assorted",
                    "vim": "Dishwash Liquid",
                    "surf": "Detergent Powder"
                ]
                
                // 2. HELP & CAPABILITY QUERIES
                if lowerInput.contains("how u help") || lowerInput.contains("what can you do") || lowerInput.contains("help me") {
                    response = "As your VSN Strategist, I am trained in: \n• Profit Margin Analysis (Ask about any product cost)\n• Inventory Optimization (Tips on stock levels)\n• Market Trend Analysis (What's popular in Vijayawada)\n• Scaling Strategies (How to double your revenue)\nWhich of these business metrics shall we tackle first?"
                }
                
                // 3. FUZZY PRODUCT LOOKUP
                if response.isEmpty {
                    // Check direct keyword mapping first
                    var targetProduct: GroceryProduct? = nil
                    for (key, fullName) in productKeywords {
                        if lowerInput.contains(key) {
                            targetProduct = store.products.first(where: { $0.name == fullName })
                            break
                        }
                    }
                    
                    // Fallback to partial name matching
                    if targetProduct == nil {
                        targetProduct = store.products.first(where: { p in
                            let name = p.name.lowercased()
                            return name.contains(lowerInput) || lowerInput.contains(name.split(separator: " ").first?.lowercased() ?? "xyz")
                        })
                    }
                    
                    if let product = targetProduct {
                        if lowerInput.contains("cost") || lowerInput.contains("price") || lowerInput.contains("rate") {
                            let margin = product.retailPrice - product.wholesalePrice
                            response = "Investment Detail for \(product.name): Your wholesale procurement rate is ₹\(Int(product.wholesalePrice)). By selling at the market rate of ₹\(Int(product.retailPrice)), you earn ₹\(Int(margin)) profit per unit. Business Tip: This item has a high 'Basket Penetration'—use it to drive traffic."
                        } else if lowerInput.contains("stock") || lowerInput.contains("buy") {
                            response = "Logistics Alert: \(product.name) is currently \(product.stockStatus.rawValue). For a business of your scale, I recommend a buffer of at least \(product.minOrderQty! * 3) units to ensure zero 'Out-of-Stock' loss."
                        } else {
                            response = "Product Insight: \(product.name) (\(product.details?.brand)) is a top-tier \(product.details?.category.rawValue) SKU. Logic: \(product.details?.description). This is a vital asset for maintaining your shop's premium reputation."
                        }
                    }
                }
                
                // 4. B2B DATASET KNOWLEDGE (Expert Consultation)
                if response.isEmpty {
                    if lowerInput.contains("delivery") || lowerInput.contains("arrive") || lowerInput.contains("when will") || lowerInput.contains("track") || lowerInput.contains("deliver") {
                        response = "Delivery Intelligence: Standard VSN wholesale orders to Vijayawada are typically fulfilled within 2 to 3 business days. High-velocity items like Oils and Ghee often arrive even faster (24-48 hours). Once you place an order, you can track its exact live status in your 'Profile' under 'My Orders'."
                    } else if lowerInput.contains("customer") || lowerInput.contains("keep") || lowerInput.contains("loyal") {
                        response = self.businessKnowledgeBase["retention"]!
                    } else if lowerInput.contains("inventory") || lowerInput.contains("manage") || lowerInput.contains("stock") {
                        response = self.businessKnowledgeBase["lean"]!
                    } else if lowerInput.contains("festival") || lowerInput.contains("season") {
                        response = self.businessKnowledgeBase["seasonal"]!
                    } else if lowerInput.contains("competitor") || lowerInput.contains("cheap") {
                        response = self.businessKnowledgeBase["competitor"]!
                    } else if lowerInput.contains("payment") || lowerInput.contains("razorpay") || lowerInput.contains("checkout") {
                        response = "Checkout Intelligence: We've integrated a high-security Razorpay gateway. To test the flow without real capital, select 'Razorpay (Test Mode)' in your cart. Use Card: 4111...1111, Expiry: 12/30, and OTP: 123456. This ensures your procurement logic is verified before going live."
                    }
                }
                
                // 5. STRATEGIC GROWTH FALLBACKS
                if response.isEmpty {
                    if lowerInput.contains("idea") || lowerInput.contains("business") || lowerInput.contains("strategy") {
                        let trending = store.products.filter { $0.isTrending }.prefix(2).map { $0.name }.joined(separator: " and ")
                        response = "Strategic Growth Pack (Vijayawada Region):\n1. Velocity Balancing: Mix 60% staples with 40% high-margin snacks.\n2. Leverage: Use the '\(store.bulkOffers.first?.title ?? "Bulk Saver")' deal to shield your margins.\n3. Trending Focus: Double your stock on \(trending) as these are currently hyper-velocity items.\nWould you like a more detailed breakdown for one of these points?"
                    } else if lowerInput.contains("product") || lowerInput.contains("display") || lowerInput.contains("show") {
                        let categories = Set(store.products.map { $0.details?.category.rawValue ?? "" }).joined(separator: ", ")
                        response = "Our Digital Catalog Intelligence:\nWe currently display premium wholesale inventory across \(store.products.count) SKUs in categories like \(categories). Specifically, we focus on brands like \(Set(store.products.map { $0.details?.brand ?? "" }).prefix(4).joined(separator: ", ")). My training ensures you get the best ROI on these specific items."
                    } else if lowerInput.contains("grow") || lowerInput.contains("scale") {
                        response = "To scale your revenue by 20-30% next month, I recommend focusing on 'Basket Value'. Encourage your customers to buy combos (e.g., Rice + Oil). Since you save ₹\(Int(store.products.first?.savings ?? 100)) on wholesale, you can pass half to them and still keep a high net profit."
                    } else if lowerInput.contains("offer") || lowerInput.contains("deal") {
                        if let topOffer = store.bulkOffers.first {
                            response = "Capital Leverage: You can currently utilize the '\(topOffer.title)' to reduce your overhead by up to 10%. This is the fastest way to increase your monthly net profit without raising retail prices."
                        } else {
                            response = "Currently scanning local Vijayawada wholesale deals... while no active flat-discounts are live, our base wholesale price on Staples is 12% lower than mandi rates today."
                        }
                    } else {
                        response = "I'm analyzing your request via our B2B model, but I couldn't find a direct match. Did you mean to ask about 'Rice cost', 'Business Ideas', or 'Stock optimization'? I'm here to help you maximize your shop's profit."
                    }
                }
            } else {
                response = "Connection to VSN Data Hub interrupted. General Wholesale Advice: Always maintain a 20% liquid cash reserve for bulk opportunities."
            }
            
            withAnimation(.spring()) {
                self.messages.append(Message(content: response, isUser: false))
                self.isTyping = false
            }
            HapticManager.shared.notify(.success)
        }
    }
}

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var productStore: GroceryProductStore
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    init(productStore: GroceryProductStore) {
        self.productStore = productStore
        self._viewModel = StateObject(wrappedValue: ChatViewModel(productStore: productStore))
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header (Premium Intelligence)
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColors.secondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(AppColors.goldGradient)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STRATEGIC AI")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundColor(AppColors.secondary)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppColors.success)
                                .frame(width: 6, height: 6)
                                .glow(color: AppColors.success, radius: 3)
                            Text("Operational Intelligence Live")
                                .font(.caption2.bold())
                                .foregroundColor(AppColors.textSecondary.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { 
                        HapticManager.shared.trigger(.medium)
                        dismiss() 
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(12)
                            .background(AppColors.textPrimary.opacity(0.05))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(AppColors.background)
                .overlay(
                    VStack {
                        Spacer()
                        Divider().background(AppColors.textPrimary.opacity(0.05))
                    }
                )
                
                // Chat Matrix
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                ModernTypingIndicator()
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(24)
                    }
                    .onChange(of: viewModel.messages) { _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Interface
                VStack(spacing: 16) {
                    if viewModel.messages.count <= 2 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ModernSuggestionChip(text: "MARGINE ANALYSIS") { viewModel.sendMessage("Analyze my current profit margins") }
                                ModernSuggestionChip(text: "VELOCITY TRENDS") { viewModel.sendMessage("What are the top moving items in Vijayawada?") }
                                ModernSuggestionChip(text: "SCALING MODEL") { viewModel.sendMessage("Suggest a plan to double my revenue") }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        HStack {
                            TextField("", text: $messageText, prompt: Text("Inquire about B2B optimization...").foregroundColor(AppColors.textPrimary.opacity(0.2)))
                                .font(.subheadline)
                                .foregroundColor(AppColors.textPrimary)
                                .focused($isFocused)
                        }
                        .padding(16)
                        .background(AppColors.background)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                        .shadow(color: AppColors.primary.opacity(0.1), radius: 0, x: 2, y: 2)
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                HapticManager.shared.trigger(.medium)
                                viewModel.sendMessage(messageText)
                                messageText = ""
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(messageText.isEmpty ? AnyShapeStyle(AppColors.textPrimary.opacity(0.05)) : AnyShapeStyle(AppColors.primaryGradient))
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18, weight: .black))
                                    .foregroundColor(messageText.isEmpty ? AppColors.textPrimary.opacity(0.3) : .white)
                            }
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(AppColors.background)
                .overlay(
                    VStack {
                        Divider().background(AppColors.textPrimary.opacity(0.05))
                        Spacer()
                    }
                )
            }
        }
        .hidesTabBar()
    }
}

struct ChatBubble: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(AppColors.secondary.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.goldGradient)
                }
                .padding(.bottom, 4)
            }
            
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(message.isUser ? AnyShapeStyle(AppColors.primaryGradient) : AnyShapeStyle(AppColors.background))
                    .foregroundColor(message.isUser ? .white : AppColors.textPrimary)
                    .clipShape(ChatBubbleShape(isUser: message.isUser))
                    .overlay(
                        ChatBubbleShape(isUser: message.isUser)
                            .stroke(message.isUser ? Color.white.opacity(0.1) : AppColors.primary.opacity(0.15), lineWidth: 2)
                    )
                    .shadow(color: message.isUser ? AppColors.primary.opacity(0.2) : AppColors.primary.opacity(0.1), radius: 0, x: 2, y: 2)
                
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppColors.textSecondary.opacity(0.4))
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [
                                    .topLeft,
                                    .topRight,
                                    isUser ? .bottomLeft : .bottomRight
                                ],
                                cornerRadii: CGSize(width: 8, height: 8))
        return Path(path.cgPath)
    }
}

struct ModernSuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 9, weight: .black))
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.background)
                .foregroundColor(AppColors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColors.primary.opacity(0.15), lineWidth: 2))
                .shadow(color: AppColors.primary.opacity(0.1), radius: 0, x: 2, y: 2)
        }
    }
}

struct ModernTypingIndicator: View {
    @State private var animStep = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppColors.secondary)
                    .frame(width: 4, height: 4)
                    .opacity(animStep == index ? 1 : 0.3)
                    .scaleEffect(animStep == index ? 1.2 : 1.0)
            }
            
            Text("STRATEGIZING")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(AppColors.secondary)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppColors.secondary.opacity(0.2), lineWidth: 1))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    animStep = (animStep + 1) % 3
                }
            }
        }
    }
}

#Preview {
    AIChatView(productStore: GroceryProductStore())
}
