import SwiftUI
import SwiftData

// Temporary cart item struct
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
    
    // New States for Utang Tracking
    @State private var selectedCustomer: Customer? = nil
    @State private var isPaid: Bool = true
    
    var cartTotal: Double {
        cart.reduce(0) { $0 + ($1.product.sellingPrice * Double($1.quantity)) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TOP: Inventory List
                List(products) { product in
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
                        
                        // Cart Preview
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(cart) { item in
                                    Text("\(item.quantity)x \(item.product.name)")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // NEW: Customer & Payment Options
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
                        
                        // Totals and Action
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total:")
                                    .font(.subheadline)
                                Text("₱\(String(format: "%.2f", cartTotal))")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Spacer()
                            
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
        }
    }
    
    // MARK: - Logic Functions
    
    private func addToCart(product: Product) {
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
    }
    
    private func completeCheckout() {
        var totalAmount: Double = 0
        var totalProfit: Double = 0
        
        // 1. Create the Sale receipt, attaching the payment status and customer
        let newSale = Sale(date: Date(), isPaid: isPaid, totalAmount: 0, totalProfit: 0)
        newSale.customer = selectedCustomer
        
        // 2. Process items
        for cartItem in cart {
            let saleItem = SaleItem(product: cartItem.product, quantitySold: cartItem.quantity)
            saleItem.sale = newSale
            
            cartItem.product.stockQuantity -= cartItem.quantity
            
            totalAmount += (saleItem.sellingPriceAtSale * Double(cartItem.quantity))
            totalProfit += saleItem.itemProfit
        }
        
        // 3. Finalize totals
        newSale.totalAmount = totalAmount
        newSale.totalProfit = totalProfit
        
        // 4. Save to SwiftData
        modelContext.insert(newSale)
        
        // 5. Reset the UI for the next transaction
        cart.removeAll()
        selectedCustomer = nil
        isPaid = true
    }
}
