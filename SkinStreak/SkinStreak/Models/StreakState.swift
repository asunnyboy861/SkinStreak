import Foundation
import SwiftData

@Model
final class StreakState {
    var current: Int = 0
    var longest: Int = 0
    var lastCheckInDay: Date?
    var freezesLeft: Int = 2
    var freezeMonthKey: String = ""

    init() {}
}
