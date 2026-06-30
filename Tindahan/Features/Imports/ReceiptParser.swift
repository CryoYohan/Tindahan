import Foundation

// A temporary structure to hold the data before it gets saved to SwiftData
struct ParsedItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Int
    var price: Double
}

class ReceiptParser {
    
    static func parse(rawText: String) -> [ParsedItem] {
        var extractedItems: [ParsedItem] = []
        
        // Split the raw text into individual lines and remove empty ones
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Regex pattern to identify a price (e.g., "8.15" or "4.13")
        let priceRegex = try! NSRegularExpression(pattern: "^\\d+\\.\\d{1,2}$")
        
        var currentNameBuffer = ""
        
        for line in lines {
            let range = NSRange(location: 0, length: line.utf16.count)
            let isPrice = priceRegex.firstMatch(in: line, options: [], range: range) != nil
            
            if isPrice, let price = Double(line) {
                // We found a price! Package the stored name and this price together.
                let cleanName = currentNameBuffer.trimmingCharacters(in: .whitespaces)
                
                if !cleanName.isEmpty {
                    extractedItems.append(ParsedItem(name: cleanName, quantity: 1, price: price))
                }
                
                // Reset the buffer for the next item on the receipt
                currentNameBuffer = ""
                
            } else {
                // If it's not a price, check if it's a barcode (just a long string of numbers)
                let isBarcode = line.allSatisfy { $0.isNumber } && line.count > 5
                
                // If it's not a barcode, it must be the item name. Add it to the buffer.
                if !isBarcode {
                    currentNameBuffer += line + " "
                }
            }
        }
        
        return extractedItems
    }
}
