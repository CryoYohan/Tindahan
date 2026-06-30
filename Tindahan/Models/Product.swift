import Foundation
import SwiftData

@Model
class Product {
    @Attribute(.unique) var barcode: String
    var name: String
    var category: String
    
    // Pricing
    var costPrice: Double
    var sellingPrice: Double
    
    // Inventory
    var stockQuantity: Int
    var lowStockThreshold: Int
    var expirationDate: Date?
    
    // Relationship: A product can appear on many receipts.
    // .nullify means if you delete this product, the past SaleItems keep the historical record but unlink the product.
    @Relationship(deleteRule: .nullify, inverse: \SaleItem.product)
    var saleItems: [SaleItem]?
    
    init(barcode: String, name: String, category: String, costPrice: Double, sellingPrice: Double, stockQuantity: Int, lowStockThreshold: Int = 5, expirationDate: Date? = nil) {
        self.barcode = barcode
        self.name = name
        self.category = category
        self.costPrice = costPrice
        self.sellingPrice = sellingPrice
        self.stockQuantity = stockQuantity
        self.lowStockThreshold = lowStockThreshold
        self.expirationDate = expirationDate
    }
}
