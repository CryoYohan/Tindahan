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
    
    // The temporary cart state
    @State private var cart: [CartItem] = []
    
    // Computed property to calculate the cart's running total
    var cartTotal: Double {
        cart.reduce(0) { $0 + ($1.product.sellingPrice * Double($1.quantity)) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TOP: Inventory List to tap and add to cart
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
                        .buttonStyle(.plain) // Prevents the whole row from acting as a button
                    }
                }
                
                // BOTTOM: Cart Summary & Checkout Button
                if !cart.isEmpty {
                    VStack {
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
                        .padding(.top, 8)
                        
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
                        .padding()
                    }
                    .background(Color(UIColor.systemBackground).shadow(radius: 5))
                }
            }
            .navigationTitle("Point of Sale")
        }
    }
    
    // MARK: - Logic Functions
    
    private func addToCart(product: Product) {
        // If it's already in the cart, increase quantity. Otherwise, add new.
        if let index = cart.firstIndex(where: { $0.product.id == product.id }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(product: product, quantity: 1))
        }
    }
    
    private func completeCheckout() {
        var totalAmount: Double = 0
        var totalProfit: Double = 0
        
        // 1. Create the master Sale receipt
        let newSale = Sale(date: Date(), isPaid: true, totalAmount: 0, totalProfit: 0)
        
        // 2. Loop through the cart to create locked-in SaleItems and deduct stock
        for cartItem in cart {
            let saleItem = SaleItem(product: cartItem.product, quantitySold: cartItem.quantity)
            saleItem.sale = newSale // Link it to the receipt
            
            // Deduct the physical stock in the database
            cartItem.product.stockQuantity -= cartItem.quantity
            
            // Tally the totals using the locked-in snapshot prices
            totalAmount += (saleItem.sellingPriceAtSale * Double(cartItem.quantity))
            totalProfit += saleItem.itemProfit
        }
        
        // 3. Finalize the receipt totals
        newSale.totalAmount = totalAmount
        newSale.totalProfit = totalProfit
        
        // 4. Save to SwiftData
        modelContext.insert(newSale)
        
        // 5. Clear the UI for the next customer
        cart.removeAll()
    }
}
