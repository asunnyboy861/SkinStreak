import Foundation

nonisolated struct ConflictRule: Codable, Identifiable, Equatable {
    let id: String
    let a: String
    let b: String
    let severity: String
    let mechanism: String
    let evidenceGrade: String
    let source: String
    let resolution: String
    let userCopy: String
}

nonisolated struct ConflictRulesFile: Codable {
    let version: String
    let rules: [ConflictRule]
}

struct ConflictFinding: Identifiable, Equatable {
    let rule: ConflictRule
    let productAName: String
    let productBName: String
    var id: String { rule.id + "|" + productAName + "|" + productBName }
}

enum ConflictEngine {
    static let familyKeywords: [(family: String, keywords: [String])] = [
        ("adapalene", ["adapalene"]),
        ("tretinoin", ["tretinoin", "retinoic acid", "tazarotene", "trifarotene"]),
        ("retinol_family", ["retinol", "retinal", "retinyl", "retinoate", "hydroxypinacolone"]),
        ("bpo", ["benzoyl peroxide", "bpo"]),
        ("copper", ["copper tripeptide", "copper peptide", "ghk-cu", "copper gluconate", "copper pca"]),
        ("vitc", ["ascorbic", "ascorbyl"]),
        ("aha", ["glycolic", "lactic acid", "mandelic", "aha"]),
        ("bha", ["salicylic", "betaine salicylate", "willow bark"]),
        ("pha", ["gluconolactone", "lactobionic", "polyhydroxy", "pha"]),
        ("azelaic", ["azelaic"]),
        ("sulfur", ["sulfur", "sulphur"]),
        ("enzyme", ["papain", "bromelain", "protease", "enzyme"]),
        ("hydroquinone", ["hydroquinone"]),
        ("tca", ["trichloroacetic"]),
        ("alcohol", ["alcohol denat", "denatured alcohol", "sd alcohol", "ethanol", "isopropyl alcohol"]),
        ("niacinamide", ["niacinamide", "nicotinamide"]),
        ("peptides", ["peptide", "matrixyl", "argireline"])
    ]

    private static var cachedRules: [ConflictRule]?

    static func loadRules() -> [ConflictRule] {
        if let cached = cachedRules { return cached }
        guard let url = Bundle.main.url(forResource: "conflict_rules", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ConflictRulesFile.self, from: data) else {
            return []
        }
        cachedRules = file.rules
        return file.rules
    }

    static var ruleCount: Int { loadRules().count }

    static func family(of active: String) -> String? {
        let lowered = active.lowercased()
        for entry in familyKeywords where entry.keywords.contains(where: { lowered.contains($0) }) {
            return entry.family
        }
        return nil
    }

    static func families(in actives: [String]) -> Set<String> {
        Set(actives.compactMap { family(of: $0) })
    }

    static func check(product: Product, cabinet: [Product]) -> [ConflictFinding] {
        let rules = loadRules()
        guard !rules.isEmpty, !product.actives.isEmpty else { return [] }
        let productFamilies = families(in: product.actives)
        guard !productFamilies.isEmpty else { return [] }

        var findings: [ConflictFinding] = []
        var seenPairs = Set<String>()
        for other in cabinet where other.name != product.name {
            let otherFamilies = families(in: other.actives)
            guard !otherFamilies.isEmpty else { continue }
            for rule in rules {
                let forward = productFamilies.contains(rule.a) && otherFamilies.contains(rule.b)
                let reverse = productFamilies.contains(rule.b) && otherFamilies.contains(rule.a)
                if forward || reverse {
                    let pairKey = rule.id + "|" + other.name
                    if seenPairs.insert(pairKey).inserted {
                        findings.append(ConflictFinding(rule: rule, productAName: product.name, productBName: other.name))
                    }
                }
            }
        }
        let rank = ["high": 0, "medium": 1, "low": 2]
        return findings.sorted {
            (rank[$0.rule.severity] ?? 3, $0.rule.id) < (rank[$1.rule.severity] ?? 3, $1.rule.id)
        }
    }

    static func separationHint(for rule: ConflictRule) -> String {
        rule.resolution
    }
}
