import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    var imageData: Data = Data()
    var capturedAt: Date = Date()
    var meanLuma: Double = 0
    var passedLightGuard: Bool = true

    init(imageData: Data, capturedAt: Date = Date(), meanLuma: Double, passedLightGuard: Bool = true) {
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.meanLuma = meanLuma
        self.passedLightGuard = passedLightGuard
    }
}
