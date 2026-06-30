import SwiftUI

struct BulkImportView: View {
    @State private var isScanning = false
    @State private var rawReceiptText = ""

    var body: some View {
        NavigationStack {
            VStack {
                if rawReceiptText.isEmpty {
                    ContentUnavailableView(
                        "Scan Supplier Receipt",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Use the camera to scan paper receipts and instantly extract the text for bulk inventory updates.")
                    )
                } else {
                    ScrollView {
                        Text(rawReceiptText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced)) // Monospaced helps align numbers
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                }

                Spacer()

                Button(action: {
                    isScanning = true
                }) {
                    Label("Scan Document", systemImage: "camera.viewfinder")
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
        }
    }
}
