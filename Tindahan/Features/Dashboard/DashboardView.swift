import SwiftUI
import SwiftData
import Charts // Apple's native data visualization framework

struct DashboardView: View {
    // Fetch all sales, sorted by newest first
    @Query(sort: \Sale.date, order: .reverse) private var allSales: [Sale]
    
    // Aggregation: Today's snapshot
    var todaysSales: [Sale] {
        allSales.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    var totalRevenueToday: Double {
        todaysSales.reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalProfitToday: Double {
        todaysSales.reduce(0) { $0 + $1.totalProfit }
    }
    
    // Aggregation: Last 7 days for the chart
    var weeklySalesData: [(day: Date, revenue: Double, profit: Double)] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        let recentSales = allSales.filter { $0.date >= oneWeekAgo }
        
        // Group sales by day
        let grouped = Dictionary(grouping: recentSales) { sale in
            calendar.startOfDay(for: sale.date)
        }
        
        // Map to an array of tuples for the chart
        return grouped.map { (key, sales) in
            let dailyRevenue = sales.reduce(0) { $0 + $1.totalAmount }
            let dailyProfit = sales.reduce(0) { $0 + $1.totalProfit }
            return (day: key, revenue: dailyRevenue, profit: dailyProfit)
        }.sorted { $0.day < $1.day }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Top KPI Cards
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Revenue").font(.caption).foregroundColor(.secondary)
                            Text("₱\(String(format: "%.2f", totalRevenueToday))").font(.title).bold()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Today's Tubó").font(.caption).foregroundColor(.secondary)
                            Text("₱\(String(format: "%.2f", totalProfitToday))")
                                .font(.title).bold().foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Swift Charts: 7-Day Trend
                if !weeklySalesData.isEmpty {
                    Section("7-Day Profit Trend") {
                        Chart(weeklySalesData, id: \.day) { dataPoint in
                            BarMark(
                                x: .value("Day", dataPoint.day, unit: .day),
                                y: .value("Profit", dataPoint.profit)
                            )
                            .foregroundStyle(Color.green.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .padding(.vertical)
                    }
                }
                
                // Recent Transactions List
                Section("Today's Receipts") {
                    if todaysSales.isEmpty {
                        ContentUnavailableView("No Sales Yet", systemImage: "cart", description: Text("Sales logged today will appear here."))
                    } else {
                        ForEach(todaysSales) { sale in
                            HStack {
                                Text(sale.date, format: .dateTime.hour().minute())
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("₱\(String(format: "%.2f", sale.totalAmount))")
                                    .bold()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }
}
