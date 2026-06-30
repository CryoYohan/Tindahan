import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            // A Group safely switches between the empty state and the list
            // without overlapping views and breaking the toolbar.
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "No Inventory",
                        systemImage: "shippingbox",
                        description: Text("Tap the + button to add your first product.")
                    )
                } else {
                    List {
                        ForEach(products) { product in
                            NavigationLink(destination: EditProductView(product: product)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.name).font(.headline)
                                        Text(product.category).font(.subheadline).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("₱\(String(format: "%.2f", product.sellingPrice))").bold()
                                        Text("Stock: \(product.stockQuantity)")
                                            .font(.caption)
                                            .foregroundColor(product.stockQuantity <= product.lowStockThreshold ? .red : .green)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Inventory")
            // topBarTrailing is the modern equivalent to navigationBarTrailing
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            // Adding padding ensures the tap target is large enough
                            .padding()
                    }
                }
            }
            // Attached directly to the NavigationStack for stability
            .sheet(isPresented: $isShowingAddSheet) {
                AddProductView()
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(products[index])
        }
    }
}
