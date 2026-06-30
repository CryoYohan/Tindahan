import Foundation
import SwiftData

@Model
class Sale {
    var id: UUID
    var date: Date
    var isPaid: Bool // True = Cash, False = Utang
    
    // Pre-calculated totals for fast UI loading
    var totalAmount: Double
    var totalProfit: Double
    
    // Relationships
    var customer: Customer?
    
    // .cascade means if you delete a Sale receipt, all its individual line items are permanently deleted too.
    @Relationship(deleteRule: .cascade)
    var items: [SaleItem]?
    
    init(id: UUID = UUID(), date: Date = Date(), isPaid: Bool = true, totalAmount: Double = 0.0, totalProfit: Double = 0.0) {
        self.id = id
        self.date = date
        self.isPaid = isPaid
        self.totalAmount = totalAmount
        self.totalProfit = totalProfit
        self.items = []
    }
}
