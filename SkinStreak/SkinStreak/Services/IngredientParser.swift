import Foundation

nonisolated enum IngredientParser {
    static let synonyms: [String: String] = [
        "bpo": "benzoyl peroxide",
        "benzoylproxide": "benzoyl peroxide",
        "vitamin c": "ascorbic acid",
        "aqua": "water",
        "eau": "water",
        "tocopherol": "vitamin e",
        "tocopheryl acetate": "vitamin e acetate",
        "nicotinamide": "niacinamide",
        "parfum": "fragrance",
        "aroma": "fragrance",
        "denatured alcohol": "alcohol denat",
        "sd alcohol": "alcohol denat",
        "alcohol denatured": "alcohol denat",
        "glycolate": "glycolic acid",
        "lactate": "lactic acid",
        "salicylate": "salicylic acid",
        "retinal": "retinaldehyde",
        "vitamin a": "retinyl palmitate",
        "ghk-cu": "copper tripeptide-1",
        "copper peptide": "copper tripeptide-1"
    ]

    static let ignoreList: Set<String> = ["", "-", "etc."]

    static func normalize(_ raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;•|\n\t")
        let parts = raw.components(separatedBy: separators)
        var result: [String] = []
        var seen = Set<String>()
        for part in parts {
            var piece = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            piece = piece.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            piece = piece.replacingOccurrences(of: "\\*+", with: "", options: .regularExpression)
            piece = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            piece = piece.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
            if ignoreList.contains(piece) || piece.count < 2 { continue }
            let mapped = synonyms[piece] ?? piece
            if seen.insert(mapped).inserted {
                result.append(mapped)
            }
        }
        return result
    }

    static func recognizedActives(from ingredientsRaw: String) -> [String] {
        let ingredients = normalize(ingredientsRaw)
        var actives: [String] = []
        var seenFamilies = Set<String>()
        for ingredient in ingredients {
            guard let family = ConflictEngine.family(of: ingredient) else { continue }
            if seenFamilies.insert(family).inserted {
                actives.append(displayName(for: ingredient))
            }
        }
        return actives
    }

    static func displayName(for ingredient: String) -> String {
        let base = ingredient.replacingOccurrences(of: "-", with: " ")
        return base.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
    }

    static func isKnownActive(_ ingredient: String) -> Bool {
        ConflictEngine.family(of: ingredient) != nil
    }
}
