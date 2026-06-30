import Foundation
import SwiftData

@Model
class Customer {
    @Attribute(.unique) var name: String
    var contactNumber: String?
    
    // Relationship: A customer can have many sales (utang).
    // .nullify means if you delete the customer, their past sales aren't deleted, they just become anonymous cash sales.
    @Relationship(deleteRule: .nullify, inverse: \Sale.customer)
    var purchases: [Sale]?
    
    init(name: String, contactNumber: String? = nil) {
        self.name = name
        self.contactNumber = contactNumber
    }
}
