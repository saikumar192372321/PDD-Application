import Foundation
import SwiftUI

#if canImport(Razorpay)
import Razorpay
#endif

// This manager handles the Razorpay Checkout flow
class RazorpayPaymentHandler: NSObject {
    static let shared = RazorpayPaymentHandler()
    
    var onPaymentSuccess: ((String) -> Void)?
    var onPaymentError: ((String) -> Void)?
    
    #if canImport(Razorpay)
    private var razorpay: RazorpayCheckout?
    #endif
    
    override init() {
        super.init()
        #if canImport(Razorpay)
        razorpay = RazorpayCheckout.initWithKey(APIConfig.razorpayKeyID, andDelegate: self)
        #endif
    }
    
    func startPayment(amount: Double, userEmail: String, orderID: String) {
        #if canImport(Razorpay)
        let options: [String: Any] = [
            "key": APIConfig.razorpayKeyID,
            "amount": Int(amount * 100), // amount in paise
            "currency": "INR",
            "name": "VSN HOME",
            "description": "Test Payment",
            "image": "https://vsn-home.in/logo.png",
            "order_id": orderID,
            "prefill": [
                "email": userEmail
            ],
            "theme": [
                "color": "#1A4CC1"
            ]
        ]
        
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            razorpay?.open(options, displayController: rootVC)
        }
        #else
        print("CRITICAL: Razorpay SDK not found. Please add 'razorpay-pod' via Swift Package Manager.")
        onPaymentError?("Razorpay SDK missing. Check console for instructions.")
        #endif
    }
}

#if canImport(Razorpay)
extension RazorpayPaymentHandler: RazorpayPaymentCompletionProtocol {
    func onPaymentSuccess(_ payment_id: String) {
        onPaymentSuccess?(payment_id)
    }
    
    func onPaymentError(_ code: Int32, description str: String) {
        onPaymentError?(str)
    }
}
#endif
