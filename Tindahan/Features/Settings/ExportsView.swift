import SwiftUI
import SwiftData

struct ReportsView: View {
    // Fetch all sales for the overall report
    @Query(sort: \Sale.date, order: .reverse) private var allSales: [Sale]
    
    // Fetch all individual items sold for the category/product grouping
    @Query private var allSaleItems: [SaleItem]
    
    // State variables to hold the temporary file URLs
    @State private var overallCSV: URL?
    @State private var categoryCSV: URL?
    @State private var productCSV: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Export Data"), footer: Text("Export your sales data as CSV files to open in Excel or Apple Numbers.")) {
                    
                    if let url = overallCSV {
                        ShareLink(item: url, message: Text("Here is the Overall Sales report.")) {
                            Label("Export Overall Sales", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("Generating Overall Report...")
                            .foregroundColor(.secondary)
                    }
                    
                    if let url = categoryCSV {
                        ShareLink(item: url, message: Text("Here is the Sales by Category report.")) {
                            Label("Export by Category", systemImage: "folder.fill")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let url = productCSV {
                        ShareLink(item: url, message: Text("Here is the Sales by Product report.")) {
                            Label("Export by Product", systemImage: "cube.box.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Reports")
            .onAppear {
                // Generate all reports seamlessly in the background when the view appears
                generateAllReports()
            }
        }
    }
    
    // MARK: - Generation Manager
    private func generateAllReports() {
        DispatchQueue.global(qos: .userInitiated).async {
            let overall = createOverallCSV()
            let category = createCategoryCSV()
            let product = createProductCSV()
            
            DispatchQueue.main.async {
                self.overallCSV = overall
                self.categoryCSV = category
                self.productCSV = product
            }
        }
    }
    
    // MARK: - 1. Overall Sales Logic
    private func createOverallCSV() -> URL? {
        var csvString = "Date,Status,Total Amount (PHP),Total Profit (PHP)\n"
        
        for sale in allSales {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = dateFormatter.string(from: sale.date)
            let status = sale.isPaid ? "Paid" : "Utang"
            
            let row = "\(dateString),\(status),\(sale.totalAmount),\(sale.totalProfit)\n"
            csvString.append(row)
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tindahan_Overall_Sales.csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    // MARK: - 2. By Category Logic
        private func createCategoryCSV() -> URL? {
            var csvString = "Category,Items Sold,Total Revenue (PHP),Total Profit (PHP)\n"
            var stats: [String: (quantity: Int, revenue: Double, profit: Double)] = [:]
            
            // Group all items by their category
            for item in allSaleItems {
                // FIX: Safely unwrap the optional product before accessing its properties
                guard let product = item.product else { continue }
                
                let cat = product.category
                let qty = item.quantitySold
                let rev = item.sellingPriceAtSale * Double(qty)
                let profit = item.itemProfit
                
                if let existing = stats[cat] {
                    stats[cat] = (existing.quantity + qty, existing.revenue + rev, existing.profit + profit)
                } else {
                    stats[cat] = (qty, rev, profit)
                }
            }
            
            // Sort alphabetically and append to CSV
            for (category, data) in stats.sorted(by: { $0.key < $1.key }) {
                csvString.append("\(category),\(data.quantity),\(data.revenue),\(data.profit)\n")
            }
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tindahan_Category_Sales.csv")
            try? csvString.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
        
        // MARK: - 3. By Product Logic
        private func createProductCSV() -> URL? {
            var csvString = "Product Name,SKU/Barcode,Quantity Sold,Total Revenue (PHP),Total Profit (PHP)\n"
            var stats: [String: (barcode: String, quantity: Int, revenue: Double, profit: Double)] = [:]
            
            // Group all items by their specific product name
            for item in allSaleItems {
                // FIX: Safely unwrap the optional product before accessing its properties
                guard let product = item.product else { continue }
                
                let name = product.name
                let barcode = product.barcode.isEmpty ? "Manual Entry" : product.barcode
                let qty = item.quantitySold
                let rev = item.sellingPriceAtSale * Double(qty)
                let profit = item.itemProfit
                
                if let existing = stats[name] {
                    stats[name] = (barcode, existing.quantity + qty, existing.revenue + rev, existing.profit + profit)
                } else {
                    stats[name] = (barcode, qty, rev, profit)
                }
            }
            
            for (name, data) in stats.sorted(by: { $0.key < $1.key }) {
                csvString.append("\(name),\(data.barcode),\(data.quantity),\(data.revenue),\(data.profit)\n")
            }
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Tindahan_Product_Sales.csv")
            try? csvString.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
}
