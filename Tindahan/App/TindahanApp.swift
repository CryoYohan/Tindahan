import SwiftUI
import SwiftData

@main
struct TindahanApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Product.self, Sale.self, SaleItem.self, Customer.self])
    }
}
