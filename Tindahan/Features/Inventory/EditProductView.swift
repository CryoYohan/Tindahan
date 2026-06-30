import SwiftUI
import SwiftData

struct EditProductView: View {
    // @Bindable creates a live connection to the database row
    @Bindable var product: Product
    
    var body: some View {
        Form {
            Section("Core Details") {
                TextField("Name", text: $product.name)
                TextField("Category", text: $product.category)
                TextField("Barcode", text: $product.barcode)
            }
            
            Section("Pricing") {
                HStack {
                    Text("Cost (₱)")
                    Spacer()
                    TextField("Cost Price", value: $product.costPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Selling (₱)")
                    Spacer()
                    TextField("Selling Price", value: $product.sellingPrice, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Stock Management") {
                HStack {
                    Text("Current Stock")
                    Spacer()
                    TextField("Stock", value: $product.stockQuantity, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Low Stock Warning")
                    Spacer()
                    TextField("Threshold", value: $product.lowStockThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Profit margin calculator to help you see your Tubó instantly
            Section("Quick Stats") {
                HStack {
                    Text("Profit per item")
                    Spacer()
                    Text("₱\(String(format: "%.2f", product.sellingPrice - product.costPrice))")
                        .bold()
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Edit Product")
        .navigationBarTitleDisplayMode(.inline)
    }
}
