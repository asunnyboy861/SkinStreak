import Foundation
import SwiftData

@Model
final class SkinReport {
    var createdAt: Date = Date()
    var rednessPct: Double = 0
    var textureVar: Double = 0
    var spotCount: Int = 0
    var coachNote: String = ""
    var noteSource: String = "template"
    var isDeep: Bool = false
    var deepUsedGLM: Bool = false
    var deepSummary: String = ""
    var deepPayload: String = ""

    init(createdAt: Date = Date(), rednessPct: Double, textureVar: Double, spotCount: Int, coachNote: String = "", noteSource: String = "template", isDeep: Bool = false, deepUsedGLM: Bool = false, deepSummary: String = "", deepPayload: String = "") {
        self.createdAt = createdAt
        self.rednessPct = rednessPct
        self.textureVar = textureVar
        self.spotCount = spotCount
        self.coachNote = coachNote
        self.noteSource = noteSource
        self.isDeep = isDeep
        self.deepUsedGLM = deepUsedGLM
        self.deepSummary = deepSummary
        self.deepPayload = deepPayload
    }
}
