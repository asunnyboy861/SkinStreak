import Foundation
import UIKit
#if canImport(FoundationModels)
import FoundationModels
#endif

nonisolated struct DeepObservation: Codable, Identifiable, Equatable {
    var zone: String
    var finding: String
    var evidenceGrade: String
    var source: String
    var id: String { zone + "|" + finding }
}

nonisolated struct DeepRoutineAdjustment: Codable, Equatable {
    var productName: String?
    var action: String?
    var reason: String?
}

nonisolated struct DeepSkinReport: Codable, Equatable {
    var summary: String
    var observations: [DeepObservation]
    var routineAdjustment: DeepRoutineAdjustment?
}

struct CoachResult: Equatable {
    var note: String
    var label: String
}

struct DeepScanResult: Equatable {
    var report: DeepSkinReport
    var usedGLM: Bool
    var label: String
    var adjustmentDroppedReason: String?
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
nonisolated enum AppleIntelligenceStatus {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
        #endif
    }

    static var guidanceText: String {
        #if targetEnvironment(simulator)
        return "Apple Intelligence needs a real device. Deep insights use the template coach until you add a key."
        #else
        return "Apple Intelligence isn't active on this device. Insights use the template coach, or add your own key in Settings."
        #endif
    }
}

@available(iOS 26.0, *)
@Generable
struct SkinCoachNote {
    @Guide(description: "A short encouraging headline of at most six words.")
    var headline: String
    @Guide(description: "One or two supportive coaching sentences about the user's measured skin trends. Never state or invent numeric measurements.")
    var note: String
}
#endif

enum AIRouter {
    static func dailyCoachNote(metrics: SkinMetrics, previous: SkinReport?, fitzpatrick: Int) async -> CoachResult {
        var fmNote: String?
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            if AppleIntelligenceStatus.isAvailable {
                fmNote = try? await appleIntelligenceNote(metrics: metrics, previous: previous, fitzpatrick: fitzpatrick)
            }
            #endif
        }
        if let fmNote, !fmNote.isEmpty {
            return CoachResult(note: fmNote, label: "AI insight")
        }
        return CoachResult(note: templateNote(metrics: metrics, previous: previous), label: "Coach note")
    }

    static func deepScan(imageData: Data, metrics: SkinMetrics, fitzpatrick: Int, cabinet: [Product]) async -> DeepScanResult {
        var glmError: Error?
        if GLMClient.hasKey {
            do {
                let raw = try await glmDeepScanJSON(imageData: imageData, metrics: metrics, fitzpatrick: fitzpatrick, cabinet: cabinet)
                let report = try decodeDeepReport(raw)
                var droppedReason: String?
                var finalReport = report
                if let adjustment = report.routineAdjustment, let name = adjustment.productName, !name.isEmpty {
                    if let reason = validateAdjustment(adjustment, cabinet: cabinet) {
                        finalReport.routineAdjustment = nil
                        droppedReason = reason
                    }
                }
                return DeepScanResult(report: finalReport, usedGLM: true, label: "AI insight", adjustmentDroppedReason: droppedReason)
            } catch {
                glmError = error
            }
        }
        _ = glmError

        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            if AppleIntelligenceStatus.isAvailable {
                if let summary = try? await appleIntelligenceDeepSummary(metrics: metrics, fitzpatrick: fitzpatrick) {
                    let report = DeepSkinReport(
                        summary: summary,
                        observations: templateObservations(metrics: metrics, fitzpatrick: fitzpatrick),
                        routineAdjustment: nil
                    )
                    return DeepScanResult(report: report, usedGLM: false, label: "AI insight", adjustmentDroppedReason: nil)
                }
            }
            #endif
        }

        let report = DeepSkinReport(
            summary: templateDeepSummary(metrics: metrics, fitzpatrick: fitzpatrick),
            observations: templateObservations(metrics: metrics, fitzpatrick: fitzpatrick),
            routineAdjustment: nil
        )
        return DeepScanResult(report: report, usedGLM: false, label: "Coach note", adjustmentDroppedReason: nil)
    }

    private static func glmDeepScanJSON(imageData: Data, metrics: SkinMetrics, fitzpatrick: Int, cabinet: [Product]) async throws -> String {
        let base64 = (UIImage(data: imageData)?.jpegData(compressionQuality: 0.7) ?? imageData).base64EncodedString()
        let system = """
        You are SkinStreak's skincare coach for a wellness app (never medical advice). \
        Reply with ONLY a JSON object: {"summary": string, "observations": [{"zone": string, "finding": string, "evidenceGrade": "A"|"B"|"C"|"D", "source": string}], "routineAdjustment": {"productName": string|null, "action": string|null, "reason": string|null}}. \
        Every observation needs an evidenceGrade and a source. Never restate or invent numeric measurements. \
        Keep the tone kind and practical. For Fitzpatrick IV-VI explicitly consider post-inflammatory hyperpigmentation.
        """
        let user = """
        Fitzpatrick type \(fitzpatrick). On-device measured values (do not restate): redness \(metrics.rednessPct)%, texture variance \(metrics.textureVar), \(metrics.spotCount) spots. \
        Current cabinet: \(cabinetActivesSummary(cabinet: cabinet)). \
        Give a deep qualitative skin observation. General wellness info, not medical advice.
        """
        return try await GLMClient.chatJSON(system: system, user: user, imageBase64: base64)
    }

    private static func decodeDeepReport(_ raw: String) throws -> DeepSkinReport {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = text.data(using: .utf8) else { throw GLMError.emptyContent }
        return try JSONDecoder().decode(DeepSkinReport.self, from: data)
    }

    private static func validateAdjustment(_ adjustment: DeepRoutineAdjustment, cabinet: [Product]) -> String? {
        let name = adjustment.productName ?? ""
        let combined = name + " " + (adjustment.action ?? "")
        let actives = IngredientParser.recognizedActives(from: combined)
        guard !actives.isEmpty else { return nil }
        let candidate = Product(name: name, actives: actives)
        let findings = ConflictEngine.check(product: candidate, cabinet: cabinet)
        if findings.contains(where: { $0.rule.severity == "high" }) {
            return "Suggested change skipped — it conflicts with your cabinet."
        }
        return nil
    }

    private static func cabinetActivesSummary(cabinet: [Product]) -> String {
        guard !cabinet.isEmpty else { return "none logged yet" }
        let lines = cabinet.prefix(12).map { product in
            let actives = product.actives.isEmpty ? "no recognized actives" : "actives: \(product.actives.joined(separator: ", "))"
            return "- \(product.name) (\(actives))"
        }
        return "\n" + lines.joined(separator: "\n")
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func appleIntelligenceNote(metrics: SkinMetrics, previous: SkinReport?, fitzpatrick: Int) async throws -> String {
        let trendContext: String
        if let previous {
            let redDelta = metrics.rednessPct - previous.rednessPct
            trendContext = "Compared to the previous scan, redness changed by \(String(format: "%.1f", redDelta)) percentage points (negative means calmer)."
        } else {
            trendContext = "This is the first scan, so today becomes the personal baseline."
        }
        let prompt = """
        Fitzpatrick type \(fitzpatrick). \(trendContext) \
        Current measured values (do not restate): redness \(metrics.rednessPct)%, texture variance \(metrics.textureVar), \(metrics.spotCount) spots. \
        Write one kind coaching note about what to keep doing tonight.
        """
        let session = LanguageModelSession(instructions: "You are SkinStreak's skincare coach. Wellness only, never medical advice. Never state or invent numeric measurements. Stay under 40 words.")
        let response = try await session.respond(to: prompt, generating: SkinCoachNote.self)
        return "\(response.content.headline) — \(response.content.note)"
    }

    @available(iOS 26.0, *)
    private static func appleIntelligenceDeepSummary(metrics: SkinMetrics, fitzpatrick: Int) async throws -> String {
        let prompt = """
        Fitzpatrick type \(fitzpatrick). Measured on-device (do not restate): redness \(metrics.rednessPct)%, texture variance \(metrics.textureVar), \(metrics.spotCount) spots. \
        Write a two-sentence deep observation of overall skin calm and evenness for a wellness journal.
        """
        let session = LanguageModelSession(instructions: "You are SkinStreak's skincare coach. Wellness only, never medical advice. Never state or invent numeric measurements. Stay under 60 words.")
        let response = try await session.respond(to: prompt)
        return response.content
    }
    #endif

    static func templateNote(metrics: SkinMetrics, previous: SkinReport?) -> String {
        guard let previous else {
            return "Baseline captured. Same light, same spot each week makes your proof undeniable."
        }
        if metrics.rednessPct < previous.rednessPct - 0.5 {
            return "Skin looks calmer than your last scan — whatever you did, keep doing it."
        }
        if metrics.rednessPct > previous.rednessPct + 0.5 {
            return "A touch more redness than last time. Check that no new products are stacking tonight."
        }
        if metrics.spotCount < previous.spotCount {
            return "Fewer spots than your last scan. Progress is quiet — keep the streak alive."
        }
        return "Steady as she goes. Consistency beats intensity — tonight's check-in is the proof."
    }

    private static func templateDeepSummary(metrics: SkinMetrics, fitzpatrick: Int) -> String {
        let pih = fitzpatrick >= 4
            ? " For deeper skin tones, post-inflammatory hyperpigmentation fades slowly — consistency matters more than intensity."
            : ""
        return "Your scan is logged against your own baseline, not anyone else's. Keep the same lighting and angle so every comparison stays honest." + pih
    }

    private static func templateObservations(metrics: SkinMetrics, fitzpatrick: Int) -> [DeepObservation] {
        var observations: [DeepObservation] = [
            DeepObservation(zone: "Cheeks", finding: "Overall tone compared only to your own baseline.", evidenceGrade: "C", source: "On-device pixel analysis"),
            DeepObservation(zone: "T-zone", finding: "Texture tracked week over week under matched lighting.", evidenceGrade: "C", source: "On-device pixel analysis")
        ]
        if fitzpatrick >= 4 {
            observations.append(DeepObservation(zone: "Post-spot areas", finding: "Dark marks from past breakouts are monitored separately from active redness.", evidenceGrade: "C", source: "PIH-focused parameter set"))
        }
        return observations
    }
}
