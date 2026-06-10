import Foundation

struct ValidationHelper {
    
    /// Validates if the string is a valid email format
    /// Enforces specific domains: gmail.com, yahoo.com, saveetha.com, outlook.com
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@(?:gmail|yahoo|saveetha|outlook)\\.com"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    /// Validates if the phone number is 10 digits and starts with 6-9
    static func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[6-9][0-9]{9}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
    
    /// Validates if the password meets complexity requirements:
    /// - Min 8 characters
    /// - At least one uppercase letter
    /// - At least one lowercase letter
    /// - At least one digit
    /// - At least one special character
    static func isValidPassword(_ password: String) -> Bool {
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$"
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    /// Detailed password validation errors
    static func getPasswordError(_ password: String) -> String? {
        if password.count < 8 { return "At least 8 characters required" }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil { return "One uppercase letter (A-Z) required" }
        if password.range(of: "[a-z]", options: .regularExpression) == nil { return "One lowercase letter (a-z) required" }
        if password.range(of: "[0-9]", options: .regularExpression) == nil { return "One number (0-9) required" }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) == nil { return "One special character required" }
        return nil
    }
    
    /// Validates if the name contains only letters and spaces (min 2 chars)
    static func isValidName(_ name: String) -> Bool {
        let nameRegEx = "^[a-zA-Z\\s]{2,50}$"
        let namePred = NSPredicate(format: "SELF MATCHES %@", nameRegEx)
        return namePred.evaluate(with: name)
    }
}
