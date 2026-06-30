import SwiftUI

// Temporary placeholders so the app compiles.
// We will replace these with real files as we build them.
struct ScannerContainerView: View { var body: some View { Text("CV Scanner") } }

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
