import Foundation

struct ValidationHelper {
    
    // MARK: - Email Validation
    /// Validates if the string is a valid email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email) && email.count <= 254
    }
    
    // MARK: - Phone Validation (India)
    /// Validates if the phone number is 10 digits and starts with 6-9 (Indian format)
    static func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[6-9][0-9]{9}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        let digits = phone.filter { $0.isNumber }
        return phonePred.evaluate(with: digits)
    }
    
    // MARK: - Password Validation
    /// Validates if the password meets complexity requirements
    /// - Min 8 characters, Max 128 for security
    /// - At least one uppercase letter
    /// - At least one lowercase letter
    /// - At least one digit
    /// - At least one special character
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 && password.count <= 128 else { return false }
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$"
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    /// Detailed password validation with specific error message
    static func getPasswordError(_ password: String) -> String? {
        if password.count < 8 { return "At least 8 characters required" }
        if password.count > 128 { return "Password too long (max 128)" }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil { 
            return "One uppercase letter (A-Z) required" }
        if password.range(of: "[a-z]", options: .regularExpression) == nil { 
            return "One lowercase letter (a-z) required" }
        if password.range(of: "[0-9]", options: .regularExpression) == nil { 
            return "One number (0-9) required" }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) == nil { 
            return "One special character required" }
        return nil
    }
    
    // MARK: - Name Validation
    /// Validates if the name contains only letters and spaces (min 2, max 50 chars)
    static func isValidName(_ name: String) -> Bool {
        let nameRegEx = "^[a-zA-Z\\s]{2,50}$"
        let namePred = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
        return namePred.evaluate(with: name)
    }
    
    // MARK: - GSTIN Validation (India)
    /// Validates GST Identification Number format (India)
    /// Format: 2 digits + 5 letters + 4 digits + 1 letter + 1 digit/letter + Z + 1 alphanumeric
    static func isValidGSTIN(_ gstin: String) -> Bool {
        let gstinPattern = "^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", gstinPattern)
        return predicate.evaluate(with: gstin.uppercased())
    }
    
    // MARK: - Pincode Validation (India)
    /// Validates Indian postal code (6 digits)
    static func isValidPincode(_ pincode: String) -> Bool {
        let pincodePattern = "^[0-9]{6}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pincodePattern)
        let digits = pincode.filter { $0.isNumber }
        return predicate.evaluate(with: digits)
    }
    
    // MARK: - Shop Name Validation
    /// Shop name: 3-100 characters, letters, numbers, spaces, hyphens
    static func isValidShopName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let shopNamePattern = "^[a-zA-Z0-9\\s\\-&]{3,100}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", shopNamePattern)
        return predicate.evaluate(with: trimmed)
    }
    
    // MARK: - Address Validation
    /// Address: 5-500 characters
    static func isValidAddress(_ address: String) -> Bool {
        let trimmed = address.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count >= 5 && trimmed.count <= 500
    }
    
    // MARK: - Price Validation
    /// Validate product price (0 to 1 crore)
    static func isValidPrice(_ price: Double) -> Bool {
        return price > 0 && price <= 10000000
    }
    
    // MARK: - Quantity Validation
    /// Validate order quantity (1 to 1000 units)
    static func isValidQuantity(_ quantity: Int) -> Bool {
        return quantity > 0 && quantity <= 1000
    }
    
    // MARK: - Input Sanitization
    /// Sanitize user input to prevent XSS attacks
    static func sanitizeInput(_ input: String) -> String {
        return input
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "&", with: "&amp;")
    }
    
    // MARK: - Form Validation Helpers
    /// Validate complete sign-up form
    static func validateSignUpForm(
        email: String,
        password: String,
        confirmPassword: String,
        shopName: String,
        phone: String
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if !isValidEmail(email) {
            errors.append("Invalid email address")
        }
        
        if let passwordError = getPasswordError(password) {
            errors.append(passwordError)
        }
        
        if password != confirmPassword {
            errors.append("Passwords do not match")
        }
        
        if !isValidShopName(shopName) {
            errors.append("Shop name must be 3-100 characters (letters, numbers, space, hyphen, &)")
        }
        
        if !isValidPhone(phone) {
            errors.append("Invalid phone number (10 digits, starts with 6-9)")
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Validate checkout form
    static func validateCheckoutForm(
        address: String,
        city: String,
        pincode: String,
        phone: String
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if !isValidAddress(address) {
            errors.append("Address must be 5-500 characters")
        }
        
        let trimmedCity = city.trimmingCharacters(in: .whitespaces)
        if trimmedCity.isEmpty || trimmedCity.count < 2 {
            errors.append("Please enter valid city name")
        }
        
        if !isValidPincode(pincode) {
            errors.append("Invalid pincode (must be 6 digits)")
        }
        
        if !isValidPhone(phone) {
            errors.append("Invalid phone number")
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Validate product creation
    static func validateProductForm(
        name: String,
        price: Double,
        minQty: Int
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if name.trimmingCharacters(in: .whitespaces).count < 3 {
            errors.append("Product name must be at least 3 characters")
        }
        
        if !isValidPrice(price) {
            errors.append("Invalid price (must be > 0 and ≤ ₹1,00,00,000)")
        }
        
        if !isValidQuantity(minQty) {
            errors.append("Min quantity must be 1-1000")
        }
        
        return (errors.isEmpty, errors)
    }
}
