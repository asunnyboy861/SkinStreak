import SwiftUI
import UIKit

enum Theme {
    static let sage = Color(red: 124.0 / 255.0, green: 154.0 / 255.0, blue: 131.0 / 255.0)
    static let sageDeep = Color(red: 88.0 / 255.0, green: 118.0 / 255.0, blue: 96.0 / 255.0)
    static let coral = Color(red: 229.0 / 255.0, green: 105.0 / 255.0, blue: 94.0 / 255.0)
    static let flame = Color(red: 242.0 / 255.0, green: 165.0 / 255.0, blue: 67.0 / 255.0)
    static let sand = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.067, blue: 0.059, alpha: 1)
            : UIColor(red: 0.973, green: 0.949, blue: 0.906, alpha: 1)
    })
    static let card = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.13, blue: 0.115, alpha: 1)
            : UIColor.white
    })

    static let disclaimer = "General wellness info, not medical advice."
    static let breakDayCopy = "Day 1 — every glow-up starts here."
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct SeverityBadge: View {
    let severity: String

    private var color: Color {
        switch severity.lowercased() {
        case "high": Theme.coral
        case "medium": Theme.flame
        default: Theme.sage
        }
    }

    private var label: String {
        switch severity.lowercased() {
        case "high": "High attention"
        case "medium": "Medium"
        default: "Low"
        }
    }

    var body: some View {
        Label(label, systemImage: severity.lowercased() == "high" ? "exclamationmark.triangle.fill" : "info.circle.fill")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("\(label) severity")
    }
}

struct EvidenceGradeBadge: View {
    let grade: String

    private var color: Color {
        switch grade.uppercased() {
        case "A": Theme.sageDeep
        case "B": Theme.sage
        case "C": Theme.flame
        default: Color.secondary
        }
    }

    var body: some View {
        Text("Evidence \(grade.uppercased())")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.16), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("Evidence grade \(grade.uppercased())")
    }
}

struct ActiveChip: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.sage.opacity(0.14), in: Capsule())
            .foregroundStyle(Theme.sageDeep)
    }
}

enum Haptics {
    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
