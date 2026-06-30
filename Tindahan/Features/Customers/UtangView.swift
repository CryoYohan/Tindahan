import SwiftUI
import SwiftData

struct UtangView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Fetch all customers, sorted alphabetically
    @Query(sort: \Customer.name) private var customers: [Customer]
    
    @State private var isShowingAddCustomer = false
    @State private var newCustomerName = ""

    var body: some View {
        NavigationStack {
            Group {
                if customers.isEmpty {
                    ContentUnavailableView(
                        "No Customers",
                        systemImage: "person.2.slash",
                        description: Text("Add customers to start tracking utang.")
                    )
                } else {
                    List {
                        ForEach(customers) { customer in
                            let unpaidSales = customer.purchases?.filter { $0.isPaid == false } ?? []
                            let totalDebt = unpaidSales.reduce(0) { $0 + $1.totalAmount }
                            
                            // Wrap the row in a NavigationLink
                            NavigationLink(destination: CustomerDetailView(customer: customer)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(customer.name)
                                            .font(.headline)
                                        Text("\(unpaidSales.count) unpaid receipts")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("₱\(String(format: "%.2f", totalDebt))")
                                            .bold()
                                            .foregroundColor(totalDebt > 0 ? .red : .primary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteCustomers)
                    }
                }
            }
            .navigationTitle("Utang Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isShowingAddCustomer = true }) {
                        Image(systemName: "plus")
                            .padding()
                    }
                }
            }
            // A simple native alert to quickly add a customer name
            .alert("Add Customer", isPresented: $isShowingAddCustomer) {
                TextField("Customer Name", text: $newCustomerName)
                    .textInputAutocapitalization(.words)
                
                Button("Cancel", role: .cancel) {
                    newCustomerName = ""
                }
                
                Button("Save") {
                    addCustomer()
                }
                .disabled(newCustomerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private func addCustomer() {
        let customer = Customer(name: newCustomerName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(customer)
        newCustomerName = ""
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(customers[index])
        }
    }
}
