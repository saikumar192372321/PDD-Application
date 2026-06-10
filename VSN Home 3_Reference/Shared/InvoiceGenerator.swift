import SwiftUI
import PDFKit

@MainActor
class InvoiceGenerator {
    static func generateInvoicePDF(order: Order, selectedLanguage: AppLanguage) -> URL? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595.2, height: 841.8)) // A4 size
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Invoice_\(order.id.prefix(8)).pdf")
        
        do {
            try pdfRenderer.writePDF(to: url) { context in
                context.beginPage()
                
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
                
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.darkGray
                ]
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                // 1. Header - Business Name
                let title = "VSN HOME - INVOICE"
                title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
                
                // 2. Order Info
                let orderId = "Order ID: #\(order.id.prefix(12).uppercased())"
                orderId.draw(at: CGPoint(x: 50, y: 90), withAttributes: headerAttributes)
                
                let orderDate = "Date: \(order.date.formatted(date: .long, time: .shortened))"
                orderDate.draw(at: CGPoint(x: 50, y: 110), withAttributes: bodyAttributes)
                
                // 3. User Info
                let billTo = "BILL TO:"
                billTo.draw(at: CGPoint(x: 50, y: 150), withAttributes: headerAttributes)
                
                let userName = "Email: \(order.userEmail)"
                userName.draw(at: CGPoint(x: 50, y: 170), withAttributes: bodyAttributes)
                
                if order.requiresGSTBill {
                    let business = "Business: \(order.businessName ?? "N/A")"
                    business.draw(at: CGPoint(x: 50, y: 190), withAttributes: bodyAttributes)
                    let gstin = "GSTIN: \(order.gstNumber ?? "N/A")"
                    gstin.draw(at: CGPoint(x: 50, y: 210), withAttributes: bodyAttributes)
                }
                
                // 4. Items Table Header
                let tableHeader = "ITEMS"
                tableHeader.draw(at: CGPoint(x: 50, y: 260), withAttributes: headerAttributes)
                
                "QTY".draw(at: CGPoint(x: 400, y: 260), withAttributes: headerAttributes)
                "PRICE".draw(at: CGPoint(x: 480, y: 260), withAttributes: headerAttributes)
                
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.move(to: CGPoint(x: 50, y: 280))
                context.cgContext.addLine(to: CGPoint(x: 550, y: 280))
                context.cgContext.strokePath()
                
                // 5. Items
                var currentY: CGFloat = 300
                let items = consolidate(order.items)
                
                for item in items {
                    let name = item.product.localizedName(for: selectedLanguage)
                    name.draw(at: CGPoint(x: 50, y: currentY), withAttributes: bodyAttributes)
                    
                    let qty = "\(item.quantity)"
                    qty.draw(at: CGPoint(x: 400, y: currentY), withAttributes: bodyAttributes)
                    
                    let price = "₹\(Int(item.product.wholesalePrice * Double(item.quantity)))"
                    price.draw(at: CGPoint(x: 480, y: currentY), withAttributes: bodyAttributes)
                    
                    currentY += 25
                    
                    // Check for new page if too many items
                    if currentY > 750 {
                        context.beginPage()
                        currentY = 50
                    }
                }
                
                // 6. Footer - Totals
                currentY += 20
                context.cgContext.move(to: CGPoint(x: 50, y: currentY))
                context.cgContext.addLine(to: CGPoint(x: 550, y: currentY))
                context.cgContext.strokePath()
                
                currentY += 20
                if let offer = order.appliedOfferTitle {
                    let discountString = "Discount (\(offer)): -₹\(Int(order.discountAmount))"
                    discountString.draw(at: CGPoint(x: 350, y: currentY), withAttributes: bodyAttributes)
                    currentY += 20
                }
                
                let totalStr = "GRAND TOTAL: ₹\(Int(order.total))"
                let totalAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                totalStr.draw(at: CGPoint(x: 350, y: currentY), withAttributes: totalAttr)
                
                // 7. Thank you message
                let footer = "Thank you for shopping with VSN Home!"
                footer.draw(at: CGPoint(x: 50, y: 800), withAttributes: headerAttributes)
            }
            return url
        } catch {
            print("Could not create PDF: \(error)")
            return nil
        }
    }
    
    private static func consolidate(_ items: [GroceryCartItem]) -> [GroceryCartItem] {
        var dict: [String: GroceryCartItem] = [:]
        for item in items {
            if let existing = dict[item.product.name] {
                var newItem = existing
                newItem.quantity += item.quantity
                dict[item.product.name] = newItem
            } else { dict[item.product.name] = item }
        }
        return Array(dict.values).sorted { $0.product.name < $1.product.name }
    }
}
