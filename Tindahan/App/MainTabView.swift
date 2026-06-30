import SwiftUI


struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            // This is the InventoryView we drafted earlier
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "shippingbox.fill")
                }
            
            ScannerContainerView()
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
            
            BulkImportView()
                .tabItem {
                    Label("Import", systemImage: "doc.text.fill")
                }
            
            CheckoutView()
                .tabItem {
                    Label("Checkout", systemImage: "cart.fill")
                }
            
            UtangView()
                .tabItem {
                    Label("Utang", systemImage: "person.2.fill")
                }
        }
        // This ensures the tabs look native and adapt to dark/light mode
        .tint(.blue)
    }
}
