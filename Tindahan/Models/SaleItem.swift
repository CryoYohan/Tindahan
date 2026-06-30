import Foundation
import SwiftData

@Model
class SaleItem {
    var id: UUID
    var quantitySold: Int
    
    // Historical price snapshots (Crucial for retail!)
    var sellingPriceAtSale: Double
    var costPriceAtSale: Double
    
    // Relationships
    var sale: Sale?
    var product: Product?
    
    init(id: UUID = UUID(), product: Product, quantitySold: Int) {
        self.id = id
        self.product = product
        self.quantitySold = quantitySold
        
        // Lock in the exact prices at the moment of the transaction
        self.sellingPriceAtSale = product.sellingPrice
        self.costPriceAtSale = product.costPrice
    }
    
    // Computed property to quickly grab the profit of just this line item
    var itemProfit: Double {
        return (sellingPriceAtSale - costPriceAtSale) * Double(quantitySold)
    }
}
