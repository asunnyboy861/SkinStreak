import Foundation
import SwiftData

@Model
final class ConflictLog {
    var createdAt: Date = Date()
    var ruleID: String = ""
    var productA: String = ""
    var productB: String = ""
    var severity: String = ""
    var resolution: String = ""

    init(ruleID: String, productA: String, productB: String, severity: String, resolution: String) {
        self.ruleID = ruleID
        self.productA = productA
        self.productB = productB
        self.severity = severity
        self.resolution = resolution
    }
}
