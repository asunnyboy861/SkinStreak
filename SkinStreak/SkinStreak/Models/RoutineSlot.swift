import Foundation
import SwiftData

@Model
final class RoutineSlot {
    var day: Date = Date()
    var session: String = "PM"
    var cycleNight: String = ""
    var productName: String = ""
    var productActives: [String] = []
    var isSeparated: Bool = false
    var separationNote: String = ""
    var status: String = "pending"
    var order: Int = 0

    init(day: Date, session: String, cycleNight: String = "", productName: String, productActives: [String] = [], isSeparated: Bool = false, separationNote: String = "", order: Int = 0) {
        self.day = day
        self.session = session
        self.cycleNight = cycleNight
        self.productName = productName
        self.productActives = productActives
        self.isSeparated = isSeparated
        self.separationNote = separationNote
        self.order = order
    }
}
