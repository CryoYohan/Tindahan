import SwiftUI
import SwiftData

struct ScannerContainerView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var scannedBarcode: String = ""
    @State private var matchedProduct: Product? = nil
    @State private var isScanning: Bool = true

    var body: some View {
        NavigationStack {
            VStack {
                // The Live Camera Feed
                BarcodeScannerView(onScanned: handleScan, isScanning: $isScanning)
                    .frame(height: 350)
                    .cornerRadius(16)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isScanning ? Color.blue : Color.green, lineWidth: 3)
                            .padding()
                    )

                // Results Area
                if !isScanning {
                    VStack(spacing: 16) {
                        Text("Barcode: \(scannedBarcode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let product = matchedProduct {
                            // Product Found
                            VStack(spacing: 8) {
                                Text(product.name)
                                    .font(.title)
                                    .bold()
                                
                                HStack(spacing: 40) {
                                    VStack {
                                        Text("Price").font(.subheadline).foregroundColor(.secondary)
                                        Text("₱\(String(format: "%.2f", product.sellingPrice))")
                                            .font(.title2).bold().foregroundColor(.blue)
                                    }
                                    
                                    VStack {
                                        Text("Stock").font(.subheadline).foregroundColor(.secondary)
                                        Text("\(product.stockQuantity)")
                                            .font(.title2).bold()
                                            .foregroundColor(product.stockQuantity <= product.lowStockThreshold ? .red : .green)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            
                        } else {
                            // Product Not Found
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.largeTitle)
                                
                                Text("Unknown Product")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                
                                Text("This barcode is not in your inventory.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                        Button("Scan Next Item") {
                            scannedBarcode = ""
                            matchedProduct = nil
                            isScanning = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                } else {
                    Text("Point the camera at a barcode...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Price Checker")
        }
    }
    
    // Search the offline database for the scanned barcode
    private func handleScan(barcode: String) {
        scannedBarcode = barcode
        
        let descriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.barcode == barcode })
        
        if let foundProduct = try? modelContext.fetch(descriptor).first {
            matchedProduct = foundProduct
        } else {
            matchedProduct = nil
        }
    }
}
