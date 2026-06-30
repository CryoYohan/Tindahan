import SwiftUI
import SwiftData

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Core Details
    @State private var name = ""
    @State private var category = "Canned Goods"
    @State private var barcode = ""
    
    // Pricing & Stock
    @State private var costPrice: Double?
    @State private var sellingPrice: Double?
    @State private var stock: Int?
    @State private var lowStockThreshold: Int? = 5 // Defaults to warning at 5 items
    
    // Expiration Logic
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                    TextField("Barcode", text: $barcode)
                }
                
                Section("Pricing & Stock") {
                    TextField("Cost Price (₱)", value: $costPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Selling Price (₱)", value: $sellingPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Initial Stock", value: $stock, format: .number)
                        .keyboardType(.numberPad)
                    
                    TextField("Low Stock Warning At", value: $lowStockThreshold, format: .number)
                        .keyboardType(.numberPad)
                }
                
                Section("Expiration (Optional)") {
                    Toggle("Has Expiration Date?", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker(
                            "Expires On",
                            selection: $expirationDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("New Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    // Prevent saving if critical fields are blank
                    .disabled(name.isEmpty || costPrice == nil || sellingPrice == nil)
                }
            }
        }
    }
    
    private func saveProduct() {
        // 1. Generate a random ID if no barcode was scanned
        let finalBarcode = barcode.isEmpty ? UUID().uuidString : barcode
        
        // 2. Only pass a date to the database if the toggle was flipped on
        let finalExpiration = hasExpirationDate ? expirationDate : nil
        
        let newProduct = Product(
            barcode: finalBarcode,
            name: name,
            category: category,
            costPrice: costPrice ?? 0.0,
            sellingPrice: sellingPrice ?? 0.0,
            stockQuantity: stock ?? 0,
            lowStockThreshold: lowStockThreshold ?? 5,
            expirationDate: finalExpiration
        )
        
        modelContext.insert(newProduct)
        dismiss()
    }
}
