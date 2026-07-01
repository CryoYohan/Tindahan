import SwiftUI
import SwiftData

struct CartItem: Identifiable {
    let id = UUID()
    var product: Product
    var quantity: Int
}

struct CheckoutView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Product.name) private var products: [Product]
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var cart: [CartItem] = []
    
    @State private var searchText: String = ""
    @State private var selectedCustomer: Customer? = nil
    @State private var isPaid: Bool = true
    
    @State private var isShowingScanner = false
    @State private var isScanning = false
    @State private var showScanError = false
    @State private var scanErrorMsg = ""
    
    var cartTotal: Double {
        cart.reduce(0) { $0 + ($1.product.sellingPrice * Double($1.quantity)) }
    }
    
    var searchResults: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { product in
                let matchesName = product.name.localizedCaseInsensitiveContains(searchText)
                let matchesBarcode = !product.barcode.isEmpty && product.barcode.localizedCaseInsensitiveContains(searchText)
                return matchesName || matchesBarcode
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TOP: Inventory List
                List(searchResults) { product in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name).font(.headline)
                            Text("Stock: \(product.stockQuantity)").font(.caption)
                        }
                        Spacer()
                        Text("₱\(String(format: "%.2f", product.sellingPrice))")
                        
                        Button {
                            addToCart(product: product)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // BOTTOM: Cart Summary & Checkout
                if !cart.isEmpty {
                    VStack(spacing: 12) {
                        Divider()
                        
                        // UPDATED: Interactive Cart Preview
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(cart) { item in
                                    Button(action: {
                                        removeFromCart(item: item)
                                    }) {
                                        HStack(spacing: 6) {
                                            Text("\(item.quantity)x \(item.product.name)")
                                            Image(systemName: "xmark")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Customer & Payment Options
                        HStack {
                            Picker("Customer", selection: $selectedCustomer) {
                                Text("Walk-in").tag(Customer?(nil))
                                ForEach(customers) { customer in
                                    Text(customer.name).tag(Customer?(customer))
                                }
                            }
                            .tint(.blue)
                            
                            Spacer()
                            
                            Toggle(isPaid ? "Paid" : "Utang", isOn: $isPaid)
                                .toggleStyle(.button)
                                .tint(isPaid ? .green : .red)
                        }
                        .padding(.horizontal)
                        
                        // Totals and Actions
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total:")
                                    .font(.subheadline)
                                Text("₱\(String(format: "%.2f", cartTotal))")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            // NEW: Clear Cart Button
                            Button(action: clearCart) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .frame(width: 50, height: 50)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: completeCheckout) {
                                Text("Checkout")
                                    .bold()
                                    .frame(width: 120, height: 50)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color(UIColor.systemBackground).shadow(radius: 5))
                }
            }
            .navigationTitle("Point of Sale")
            .searchable(text: $searchText, prompt: "Search name or SKU (e.g. EGG)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isScanning = true
                        isShowingScanner = true
                    }) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .padding()
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                NavigationStack {
                    BarcodeScannerView(onScanned: handleScan, isScanning: $isScanning)
                        .navigationTitle("Scan Item")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { isShowingScanner = false }
                            }
                        }
                }
            }
            .alert("Item Not Found", isPresented: $showScanError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(scanErrorMsg)
            }
        }
    }
    
    // MARK: - Logic Functions
    
    private func addToCart(product: Product) {
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
        searchText = ""
    }
    
    // NEW: Decrease quantity by 1, or remove entirely if quantity hits 0
    private func removeFromCart(item: CartItem) {
        if let index = cart.firstIndex(where: { $0.id == item.id }) {
            if cart[index].quantity > 1 {
                cart[index].quantity -= 1
            } else {
                cart.remove(at: index)
            }
        }
    }
    
    // NEW: Clear the entire cart and reset the UI
    private func clearCart() {
        cart.removeAll()
        selectedCustomer = nil
        isPaid = true
    }
    
    private func handleScan(barcode: String) {
        if let product = products.first(where: { $0.barcode == barcode && $0.barcode != "" }) {
            addToCart(product: product)
            isShowingScanner = false
        } else {
            isShowingScanner = false
            scanErrorMsg = "No product found with barcode: \(barcode). Add it to Inventory first."
            showScanError = true
        }
    }
    
    private func completeCheckout() {
        var totalAmount: Double = 0
        var totalProfit: Double = 0
        
        let newSale = Sale(date: Date(), isPaid: isPaid, totalAmount: 0, totalProfit: 0)
        newSale.customer = selectedCustomer
        
        for cartItem in cart {
            let saleItem = SaleItem(product: cartItem.product, quantitySold: cartItem.quantity)
            saleItem.sale = newSale
            
            cartItem.product.stockQuantity -= cartItem.quantity
            
            totalAmount += (saleItem.sellingPriceAtSale * Double(cartItem.quantity))
            totalProfit += saleItem.itemProfit
        }
        
        newSale.totalAmount = totalAmount
        newSale.totalProfit = totalProfit
        
        modelContext.insert(newSale)
        
        // Reuse the new function to quickly clear the state after a successful transaction
        clearCart()
    }
}
