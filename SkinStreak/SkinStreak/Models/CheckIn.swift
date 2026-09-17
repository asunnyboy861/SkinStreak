import Foundation
import SwiftData

@Model
final class CheckIn {
    var day: Date = Date()
    var completedCount: Int = 0
    var totalCount: Int = 0
    var allDone: Bool = false

    init(day: Date, completedCount: Int, totalCount: Int, allDone: Bool) {
        self.day = day
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.allDone = allDone
    }
}
