import SwiftUI
import SwiftData
import QuickLook
import UIKit

// A simple structure to standardize our report data before exporting
struct ReportData {
    let title: String
    let headers: [String]
    let rows: [[String]]
}

// Enums to track what the user is tapping
enum ReportType { case overall, category, product }

struct ReportsView: View {
    @Query(sort: \Sale.date, order: .reverse) private var allSales: [Sale]
    @Query private var allSaleItems: [SaleItem]
    
    // UI State
    @State private var showFormatDialog = false
    @State private var selectedReport: ReportType?
    
    // QuickLook Preview State
    @State private var previewURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Export Data"), footer: Text("Select a report to preview and export as PDF or CSV.")) {
                    
                    Button(action: { triggerExportMenu(for: .overall) }) {
                        Label("Overall Sales", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                    }
                    .tint(.blue)
                    
                    Button(action: { triggerExportMenu(for: .category) }) {
                        Label("Sales by Category", systemImage: "folder.fill")
                            .font(.headline)
                    }
                    .tint(.green)
                    
                    Button(action: { triggerExportMenu(for: .product) }) {
                        Label("Sales by Product", systemImage: "cube.box.fill")
                            .font(.headline)
                    }
                    .tint(.orange)
                }
            }
            .navigationTitle("Reports")
            // 1. The Action Sheet to pick format
            .confirmationDialog("Choose Export Format", isPresented: $showFormatDialog, titleVisibility: .visible) {
                Button("PDF Document") { generateFile(format: .pdf) }
                Button("CSV Spreadsheet") { generateFile(format: .csv) }
                Button("Cancel", role: .cancel) { }
            }
            // 2. The Native Apple File Previewer
            .quickLookPreview($previewURL)
        }
    }
    
    // MARK: - Interaction Logic
    private func triggerExportMenu(for type: ReportType) {
        selectedReport = type
        showFormatDialog = true
    }
    
    private enum ExportFormat { case pdf, csv }
    
    private func generateFile(format: ExportFormat) {
        guard let type = selectedReport else { return }
        
        // Step 1: Gather the raw data based on what button was tapped
        let reportData: ReportData
        switch type {
        case .overall: reportData = getOverallData()
        case .category: reportData = getCategoryData()
        case .product: reportData = getProductData()
        }
        
        // Step 2: Convert that data to the requested file type and show preview
        if format == .csv {
            previewURL = createCSV(from: reportData)
        } else {
            previewURL = createPDF(from: reportData)
        }
    }
    
    // MARK: - Data Extractors
    
    private func getOverallData() -> ReportData {
        var rows: [[String]] = []
        for sale in allSales {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = dateFormatter.string(from: sale.date)
            let status = sale.isPaid ? "Paid" : "Utang"
            
            rows.append([
                dateString, status,
                String(format: "%.2f", sale.totalAmount),
                String(format: "%.2f", sale.totalProfit)
            ])
        }
        return ReportData(title: "Overall Sales Report", headers: ["Date", "Status", "Revenue (PHP)", "Profit (PHP)"], rows: rows)
    }
    
    private func getCategoryData() -> ReportData {
        var stats: [String: (quantity: Int, revenue: Double, profit: Double)] = [:]
        
        for item in allSaleItems {
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
        
        var rows: [[String]] = []
        for (category, data) in stats.sorted(by: { $0.key < $1.key }) {
            rows.append([
                category, "\(data.quantity)",
                String(format: "%.2f", data.revenue),
                String(format: "%.2f", data.profit)
            ])
        }
        return ReportData(title: "Sales by Category", headers: ["Category", "Items Sold", "Revenue (PHP)", "Profit (PHP)"], rows: rows)
    }
    
    private func getProductData() -> ReportData {
        var stats: [String: (barcode: String, quantity: Int, revenue: Double, profit: Double)] = [:]
        
        for item in allSaleItems {
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
        
        var rows: [[String]] = []
        for (name, data) in stats.sorted(by: { $0.key < $1.key }) {
            rows.append([
                name, data.barcode, "\(data.quantity)",
                String(format: "%.2f", data.revenue),
                String(format: "%.2f", data.profit)
            ])
        }
        return ReportData(title: "Sales by Product", headers: ["Product Name", "SKU/Barcode", "Qty Sold", "Revenue (PHP)", "Profit (PHP)"], rows: rows)
    }
    
    // MARK: - File Generators
    
    private func createCSV(from data: ReportData) -> URL? {
        // FIXED: The escape logic below prevents commas from breaking the columns
        func escape(_ text: String) -> String {
            let escapedText = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedText)\""
        }
        
        var csvString = data.headers.map { escape($0) }.joined(separator: ",") + "\n"
        
        for row in data.rows {
            csvString += row.map { escape($0) }.joined(separator: ",") + "\n"
        }
        
        let safeTitle = data.title.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).csv")
        try? csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func createPDF(from data: ReportData) -> URL? {
        // We use an HTML string to easily build a formatted table
        var html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system, Helvetica, sans-serif; padding: 20px; }
            h1 { text-align: center; color: #333; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
            th { background-color: #f4f4f4; }
        </style>
        </head>
        <body>
        <h1>\(data.title)</h1>
        <table>
            <tr>\(data.headers.map { "<th>\($0)</th>" }.joined())</tr>
        """
        
        for row in data.rows {
            html += "<tr>\(row.map { "<td>\($0)</td>" }.joined())</tr>"
        }
        
        html += "</table></body></html>"
        
        // Convert the HTML to a PDF using Apple's Print Renderer
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        
        // Standard US Letter dimensions
        let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(paperRect.insetBy(dx: 40, dy: 40), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()
        
        let safeTitle = data.title.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).pdf")
        pdfData.write(to: url, atomically: true)
        return url
    }
}
