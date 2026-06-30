import SwiftUI
import SwiftData

struct CustomerDetailView: View {
    @Bindable var customer: Customer
    
    // Sort receipts by newest first, split by payment status
    var unpaidSales: [Sale] {
        customer.purchases?.filter { $0.isPaid == false }.sorted { $0.date > $1.date } ?? []
    }
    
    var paidSales: [Sale] {
        customer.purchases?.filter { $0.isPaid == true }.sorted { $0.date > $1.date } ?? []
    }
    
    var totalDebt: Double {
        unpaidSales.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        List {
            // Master Balance Section
            Section("Total Balance Due") {
                HStack {
                    Text("Amount")
                        .font(.headline)
                    Spacer()
                    Text("₱\(String(format: "%.2f", totalDebt))")
                        .font(.title2)
                        .bold()
                        .foregroundColor(totalDebt > 0 ? .red : .green)
                }
                
                if totalDebt > 0 {
                    Button(action: settleAllDebt) {
                        Text("Mark All as Paid")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.vertical, 4)
                }
            }
            
            // Individual Unpaid Receipts
            if !unpaidSales.isEmpty {
                Section("Unpaid Receipts") {
                    ForEach(unpaidSales) { sale in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(sale.date, format: .dateTime.month().day().hour().minute())
                                    .font(.subheadline)
                                Text("\(sale.items?.count ?? 0) items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("₱\(String(format: "%.2f", sale.totalAmount))")
                                .bold()
                                .foregroundColor(.red)
                            
                            // Pay single receipt button
                            Button {
                                sale.isPaid = true
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                    }
                }
            }
            
            // Paid History for reference
            if !paidSales.isEmpty {
                Section("Payment History") {
                    ForEach(paidSales) { sale in
                        HStack {
                            Text(sale.date, format: .dateTime.month().day())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("₱\(String(format: "%.2f", sale.totalAmount))")
                                .strikethrough()
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(customer.name)
    }
    
    // Automatically marks every unpaid receipt as true
    private func settleAllDebt() {
        for sale in unpaidSales {
            sale.isPaid = true
        }
    }
}
