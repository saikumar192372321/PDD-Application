import SwiftUI
import Combine

/// SessionManager handles persistent user authentication state.
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    // Keys for UserDefaults
    @Published var isLoggedIn: Bool = false
    @Published var isAdmin: Bool = false
    @Published var userEmail: String = ""
    @Published var userCoins: Int = 0
    @Published var userName: String = ""
    @Published var userPhone: String = ""
    @Published var userAddress: String = ""
    @Published var userBusinessName: String = ""
    @Published var userGSTIN: String = ""
    @Published var referralCode: String = ""
    @Published var referredBy: String = ""
    
    private let kIsLoggedIn = "session_is_logged_in"
    private let kIsAdmin = "session_is_admin"
    private let kUserEmail = "session_user_email"
    private let kUserCoins = "session_user_coins"
    private let kUserName = "session_user_name"
    private let kUserPhone = "session_user_phone"
    private let kUserAddress = "session_user_address"
    private let kUserBusinessName = "session_user_business_name"
    private let kUserGSTIN = "session_user_gstin"
    private let kUserReferralCode = "session_user_referral_code"
    private let kUserReferredBy = "session_user_referred_by"
    
    private init() {
        // Load session on initialization
        // Non-sensitive flags in UserDefaults
        self.isLoggedIn = UserDefaults.standard.bool(forKey: kIsLoggedIn)
        self.isAdmin = UserDefaults.standard.bool(forKey: kIsAdmin)
        self.userCoins = UserDefaults.standard.integer(forKey: kUserCoins)
        
        // SENSITIVE DATA from Keychain (secure storage)
        if let email = try? KeychainManager.retrieve(key: "session_user_email", type: String.self) {
            self.userEmail = email
        }
        if let phone = try? KeychainManager.retrieve(key: "session_user_phone", type: String.self) {
            self.userPhone = phone
        }
        if let address = try? KeychainManager.retrieve(key: "session_user_address", type: String.self) {
            self.userAddress = address
        }
        if let businessName = try? KeychainManager.retrieve(key: "session_user_business_name", type: String.self) {
            self.userBusinessName = businessName
        }
        if let gstin = try? KeychainManager.retrieve(key: "session_user_gstin", type: String.self) {
            self.userGSTIN = gstin
        }
        if let name = try? KeychainManager.retrieve(key: "session_user_name", type: String.self) {
            self.userName = name
        }
        if let referralCode = try? KeychainManager.retrieve(key: "session_user_referral_code", type: String.self) {
            self.referralCode = referralCode
        }
        if let referredBy = try? KeychainManager.retrieve(key: "session_user_referred_by", type: String.self) {
            self.referredBy = referredBy
        }
    }
    
    /// Starts a new session with provided details.
    func startSession(email: String, isAdmin: Bool, name: String = "", phone: String = "", address: String = "", businessName: String = "", gstin: String = "", coins: Int = 0, referralCode: String = "", referredBy: String = "") {
        self.userEmail = email
        self.isAdmin = isAdmin
        self.userName = name
        self.userPhone = phone
        self.userAddress = address
        self.userBusinessName = businessName
        self.userGSTIN = gstin
        self.userCoins = coins
        self.referralCode = referralCode
        self.referredBy = referredBy
        self.isLoggedIn = true
        
        // Store non-sensitive flags in UserDefaults
        UserDefaults.standard.set(true, forKey: kIsLoggedIn)
        UserDefaults.standard.set(isAdmin, forKey: kIsAdmin)
        UserDefaults.standard.set(coins, forKey: kUserCoins)
        
        // Store SENSITIVE data in Keychain
        try? KeychainManager.save(email, key: "session_user_email")
        try? KeychainManager.save(name, key: "session_user_name")
        try? KeychainManager.save(phone, key: "session_user_phone")
        try? KeychainManager.save(address, key: "session_user_address")
        try? KeychainManager.save(businessName, key: "session_user_business_name")
        try? KeychainManager.save(gstin, key: "session_user_gstin")
        try? KeychainManager.save(referralCode, key: "session_user_referral_code")
        try? KeychainManager.save(referredBy, key: "session_user_referred_by")
    }
    
    func updateCoins(_ coins: Int) {
        self.userCoins = coins
        UserDefaults.standard.set(coins, forKey: kUserCoins)
    }
    
    /// Clears the current session and logs out the user.
    func clearSession() {
        self.isLoggedIn = false
        self.isAdmin = false
        self.userEmail = ""
        self.userCoins = 0
        self.userName = ""
        self.userPhone = ""
        self.userAddress = ""
        self.userBusinessName = ""
        self.userGSTIN = ""
        self.referralCode = ""
        self.referredBy = ""
        
        // Clear from UserDefaults
        UserDefaults.standard.set(false, forKey: kIsLoggedIn)
        UserDefaults.standard.removeObject(forKey: kIsAdmin)
        UserDefaults.standard.removeObject(forKey: kUserCoins)
        UserDefaults.standard.removeObject(forKey: "last_enrolled_email")
        UserDefaults.standard.removeObject(forKey: "last_enrolled_password")
        
        // Clear SENSITIVE data from Keychain
        try? KeychainManager.delete(key: "session_user_email")
        try? KeychainManager.delete(key: "session_user_name")
        try? KeychainManager.delete(key: "session_user_phone")
        try? KeychainManager.delete(key: "session_user_address")
        try? KeychainManager.delete(key: "session_user_business_name")
        try? KeychainManager.delete(key: "session_user_gstin")
        try? KeychainManager.delete(key: "session_user_referral_code")
        try? KeychainManager.delete(key: "session_user_referred_by")
    }
}
