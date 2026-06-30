//
//  Item.swift
//  Tindahan
//
//  Created by Cyril John Ypil on 6/30/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
