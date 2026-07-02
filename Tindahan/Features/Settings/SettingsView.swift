import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    // Automatically saves the name to the device's UserDefaults
    @AppStorage("userName") private var userName: String = ""
    
    // Fetch all top-level data to delete it
    @Query private var allProducts: [Product]
    @Query private var allCustomers: [Customer]
    @Query private var allSales: [Sale]
    
    // Alert State Variables
    @State private var showDeleteAlert = false
    @State private var confirmNameText = ""
    @State private var showMismatchError = false
    @State private var showSuccessMessage = false
    
    // Fallback word if the user hasn't set a name yet
    var confirmationTarget: String {
        userName.isEmpty ? "DELETE" : userName
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Personalization Section
                Section(header: Text("Profile Info"), footer: Text("This name will appear on your dashboard.")) {
                    TextField("Enter your name (e.g. Lucia)", text: $userName)
                }
                
                // MARK: - Danger Zone
                Section(header: Text("Danger Zone"), footer: Text("This will permanently delete all inventory, customers, and sales history. This action cannot be undone.")) {
                    Button(role: .destructive, action: {
                        confirmNameText = ""
                        showDeleteAlert = true
                    }) {
                        Text("Erase All Data")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            
            // 1. The Confirmation Alert with TextField
            .alert("Erase All Data", isPresented: $showDeleteAlert) {
                TextField("Type '\(confirmationTarget)'", text: $confirmNameText)
                
                Button("Cancel", role: .cancel) { }
                
                Button("Erase Everything", role: .destructive) {
                    if confirmNameText == confirmationTarget {
                        deleteAllData()
                    } else {
                        showMismatchError = true
                    }
                }
            } message: {
                Text("This action cannot be undone. Please type '\(confirmationTarget)' to confirm deletion.")
            }
            
            // 2. The Typo Error Alert
            .alert("Action Canceled", isPresented: $showMismatchError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The text you typed did not match. No data was deleted.")
            }
            
            // 3. The Success Alert
            .alert("App Reset", isPresented: $showSuccessMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All data has been successfully erased. You have a clean database.")
            }
        }
    }
    
    // MARK: - Deletion Logic
    private func deleteAllData() {
        // SwiftData doesn't have a "truncate" command, so we loop through and delete
        for product in allProducts {
            modelContext.delete(product)
        }
        for customer in allCustomers {
            modelContext.delete(customer)
        }
        for sale in allSales {
            modelContext.delete(sale)
        }
        
        // Force SwiftData to save the empty state immediately
        try? modelContext.save()
        
        showSuccessMessage = true
    }
}
