import SwiftUI
import SwiftData

struct BulkImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var existingProducts: [Product]
    
    @State private var isScanning = false
    @State private var rawReceiptText = ""
    @State private var parsedItems: [ParsedItem] = []

    var body: some View {
        NavigationStack {
            VStack {
                if parsedItems.isEmpty {
                    ContentUnavailableView(
                        "Scan Supplier Receipt",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Use the camera to scan paper receipts and automatically extract the products.")
                    )
                } else {
                    List {
                        Section(header: Text("Review & Edit Items (\(parsedItems.count))")) {
                            // By using $item, we create a direct binding so you can edit the list in place
                            ForEach($parsedItems) { $item in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        // 1. Editable Name Field
                                        TextField("Item Name", text: $item.name)
                                            .textFieldStyle(.roundedBorder)
                                        
                                        // 2. Adjustable Quantity
                                        Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...1000)
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    // 3. Editable Price Field
                                    VStack(alignment: .trailing) {
                                        Text("Cost Price")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        TextField("Price", value: $item.price, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 80)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteItem)
                        }
                    }
                    .listStyle(.insetGrouped)
                    
                    // 4. The Integration Button
                    Button(action: commitToInventory) {
                        Text("Save to Inventory")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    rawReceiptText = ""
                    isScanning = true
                }) {
                    Label(parsedItems.isEmpty ? "Scan Document" : "Scan Another Receipt", systemImage: "camera.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Receipt Import")
            .sheet(isPresented: $isScanning) {
                ReceiptScannerView(recognizedText: $rawReceiptText)
                    .ignoresSafeArea()
            }
            .onChange(of: rawReceiptText) { _, newText in
                if !newText.isEmpty {
                    parsedItems = ReceiptParser.parse(rawText: newText)
                }
            }
        }
    }
    
    // MARK: - Logic Functions
        
        private func deleteItem(at offsets: IndexSet) {
            // Wrapping in withAnimation prevents the UI from panicking when an index disappears
            withAnimation {
                parsedItems.remove(atOffsets: offsets)
            }
        }
        
        private func commitToInventory() {
            // 1. Force the keyboard to dismiss, breaking active TextField bindings
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // 2. Process the inventory data
            for item in parsedItems {
                if let existingProduct = existingProducts.first(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame }) {
                    existingProduct.stockQuantity += item.quantity
                    existingProduct.costPrice = item.price
                } else {
                    let newProduct = Product(
                        barcode: "",
                        name: item.name,
                        category: "Imported",
                        costPrice: item.price,
                        sellingPrice: 0.0,
                        stockQuantity: item.quantity
                    )
                    modelContext.insert(newProduct)
                }
            }
            
            // 3. Clear the staging area safely on the next cycle
            DispatchQueue.main.async {
                self.parsedItems.removeAll()
                self.rawReceiptText = ""
            }
        }
}
