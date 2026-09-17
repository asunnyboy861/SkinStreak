import SwiftUI

struct ConflictAlertView: View {
    let findings: [ConflictFinding]
    let onSeparate: (ConflictFinding) -> Void
    let onUseAnyway: (ConflictFinding) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    private var current: ConflictFinding? { findings.indices.contains(index) ? findings[index] : findings.first }

    var body: some View {
        VStack(spacing: 16) {
            if let finding = current {
                HStack(spacing: 14) {
                    productBadge(finding.productAName)
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(Theme.coral)
                    productBadge(finding.productBName)
                }
                .padding(.top, 26)

                Text("Heads up — these two cancel each other out. Want me to separate them?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                HStack(spacing: 8) {
                    SeverityBadge(severity: finding.rule.severity)
                    EvidenceGradeBadge(grade: finding.rule.evidenceGrade)
                }

                Text(finding.rule.userCopy)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                VStack(alignment: .leading, spacing: 10) {
                    Label(finding.rule.mechanism, systemImage: "wand.and.stars")
                        .font(.caption)
                    Label(finding.rule.source, systemImage: "book.closed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Label(finding.rule.resolution, systemImage: "arrow.triangle.swap")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.sageDeep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.secondary.opacity(0.08)))
                .padding(.horizontal, 22)

                if findings.count > 1 {
                    Text("\(index + 1) of \(findings.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button {
                    onSeparate(finding)
                } label: {
                    Text(findings.count > 1 ? "Separate them & continue" : "Separate them")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.sage)

                Button {
                    onUseAnyway(finding)
                } label: {
                    Text(findings.count > 1 ? "Use anyway & continue" : "Use anyway")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.sand.ignoresSafeArea())
    }

    private func productBadge(_ name: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.title3)
                .foregroundStyle(Theme.sage)
            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 120)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
    }
}
