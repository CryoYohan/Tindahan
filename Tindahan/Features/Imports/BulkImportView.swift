import SwiftUI

struct BulkImportView: View {
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
                        Section(header: Text("Extracted Items (\(parsedItems.count))")) {
                            ForEach(parsedItems) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text("Quantity: \(item.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("₱\(String(format: "%.2f", item.price))")
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                Spacer()

                Button(action: {
                    // Reset everything for a fresh scan
                    rawReceiptText = ""
                    isScanning = true
                }) {
                    Label(parsedItems.isEmpty ? "Scan Document" : "Scan Another Receipt", systemImage: "camera.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Receipt Import")
            .sheet(isPresented: $isScanning) {
                ReceiptScannerView(recognizedText: $rawReceiptText)
                    .ignoresSafeArea()
            }
            // Trigger the parser the exact millisecond the camera hands back the text
            .onChange(of: rawReceiptText) { _, newText in
                if !newText.isEmpty {
                    parsedItems = ReceiptParser.parse(rawText: newText)
                }
            }
        }
    }
}
