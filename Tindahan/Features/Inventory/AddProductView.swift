import SwiftUI
import SwiftData

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var category = "Snacks"
    @State private var barcode = ""
    @State private var costPrice: Double?
    @State private var sellingPrice: Double?
    @State private var stockQuantity: Int?
    
    // Scanner State
    @State private var isShowingScanner = false
    @State private var isScanning = false
    
    let categories = [
        "Snacks",
        "Beverages & Liquor",
        "Instant Noodles",
        "Canned Goods",
        "Rice & Eggs",
        "Cooking Essentials",
        "Milk, Coffee, & etc.",
        "Toiletries",
        "Laundry & Cleaning",
        "Cigarettes & Lighters",
        "Other"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    // The new Barcode Row with integrated scanner
                    HStack {
                        TextField("Barcode (Optional)", text: $barcode)
                            .keyboardType(.numberPad)
                        
                        Button {
                            isScanning = true
                            isShowingScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Pricing & Stock") {
                    TextField("Cost Price (₱)", value: $costPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Selling Price (₱)", value: $sellingPrice, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Initial Stock", value: $stockQuantity, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveProduct() }
                        .disabled(name.isEmpty || sellingPrice == nil)
                }
            }
            // Present the camera as a pop-up sheet
            .sheet(isPresented: $isShowingScanner) {
                NavigationStack {
                    BarcodeScannerView(onScanned: { scannedCode in
                        self.barcode = scannedCode
                        self.isShowingScanner = false // Auto-dismiss when found
                    }, isScanning: $isScanning)
                    .navigationTitle("Scan Barcode")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { isShowingScanner = false }
                        }
                    }
                }
            }
        }
    }
    
    private func saveProduct() {
            // We initialize Product exactly matching the order and types it expects
            let product = Product(
                barcode: barcode, // Moved to the top, and 'nil' check removed
                name: name,
                category: category,
                costPrice: costPrice ?? 0,
                sellingPrice: sellingPrice ?? 0,
                stockQuantity: stockQuantity ?? 0
            )
            
            modelContext.insert(product)
            dismiss()
        }
}
