import Foundation
import SwiftData

@Model
final class Product {
    var name: String = ""
    var brand: String = ""
    var barcode: String = ""
    var ingredientsRaw: String = ""
    var actives: [String] = []
    var avoidSession: String = ""
    var avoidNote: String = ""
    var addedAt: Date = Date()

    init(name: String, brand: String = "", barcode: String = "", ingredientsRaw: String = "", actives: [String] = []) {
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.ingredientsRaw = ingredientsRaw
        self.actives = actives
    }
}
