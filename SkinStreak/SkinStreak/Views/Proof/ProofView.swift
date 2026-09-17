import SwiftData
import SwiftUI
import UIKit

struct ProofView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementManager
    @Query private var photos: [ProgressPhoto]
    @Query private var reports: [SkinReport]
    @Query private var logs: [ConflictLog]
    @Query private var streaks: [StreakState]
    @State private var showCamera = false
    @State private var showPaywall = false
    @State private var showShare = false
    @State private var shareURL: URL?

    private var sortedPhotos: [ProgressPhoto] { photos.sorted { $0.capturedAt < $1.capturedAt } }
    private var sortedReports: [SkinReport] { reports.sorted { $0.createdAt < $1.createdAt } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    captureCard
                    if sortedPhotos.count >= 2, let before = sortedPhotos.first, let after = sortedPhotos.last {
                        BeforeAfterSlider(before: before, after: after)
                    }
                    if entitlements.isPro {
                        weekReportCard
                        shareCard
                    } else {
                        lockedReportCard
                    }
                    timelineCard
                }
                .padding()
            }
            .background(Theme.sand.ignoresSafeArea())
            .navigationTitle("Proof")
            .fullScreenCover(isPresented: $showCamera) {
                GuidedCaptureView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showShare) {
                shareSheet
            }
        }
    }

    private var captureCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 34))
                .foregroundStyle(Theme.sage)
            Text("Same light. Same spot. Real proof.")
                .font(.headline)
            Text("Your weekly aligned photo powers every trend below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showCamera = true
            } label: {
                Label("Take this week's photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Proof report")
                    .font(.headline)
                Spacer()
                Text("measured")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.sage.opacity(0.16), in: Capsule())
                    .foregroundStyle(Theme.sageDeep)
            }
            if sortedReports.count >= 2, let baseline = sortedReports.first, let latest = sortedReports.last {
                trendRow("Redness", from: baseline.rednessPct, to: latest.rednessPct, format: "%.1f%%", lowerIsBetter: true)
                trendRow("Texture variance", from: baseline.textureVar, to: latest.textureVar, format: "%.2f", lowerIsBetter: true)
                trendRow("Visible spots", from: Double(baseline.spotCount), to: Double(latest.spotCount), format: "%.0f", lowerIsBetter: true)
                Text(attribution)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Two scans make a trend. Capture your baseline this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func trendRow(_ label: String, from: Double, to: Double, format: String, lowerIsBetter: Bool) -> some View {
        let change = from > 0 ? (to - from) / from * 100 : 0
        let improved = lowerIsBetter ? change < 0 : change > 0
        return HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text("\(String(format: format, from)) → \(String(format: format, to))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            Text(changeText(change))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(improved ? Theme.sageDeep : Theme.flame)
                .frame(width: 74, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func changeText(_ change: Double) -> String {
        let sign = change > 0 ? "+" : change < 0 ? "−" : ""
        return "\(sign)\(String(format: "%.0f", abs(change)))%"
    }

    private var attribution: String {
        let cutoff = Date().addingTimeInterval(-14 * 24 * 3600)
        let recent = logs.filter { $0.createdAt >= cutoff }.sorted { $0.createdAt > $1.createdAt }
        if let latest = recent.first {
            return "Right around when you separated \(latest.productA) and \(latest.productB)."
        }
        return "No product conflicts logged in the last two weeks — a steady routine."
    }

    private var lockedReportCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.flame)
            Text("Weekly Proof report")
                .font(.headline)
            Text("Trends, conflict attribution and share cards unlock with Pro. Check-ins, streaks and photos stay free forever.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showPaywall = true
            } label: {
                Text("Unlock with Pro")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var shareCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 26))
                .foregroundStyle(Theme.sage)
            Text("Share your proof")
                .font(.headline)
            Text("A 9:16 story card of your measured trend — nobody's before-after filters, just your data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                renderShareCard()
                showShare = true
            } label: {
                Text("Create share card")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var shareSheet: some View {
        VStack(spacing: 16) {
            if let shareURL, let image = UIImage(contentsOfFile: shareURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                ShareLink(item: shareURL, preview: SharePreview("My SkinStreak proof")) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                ProgressView("Building your card…")
            }
        }
        .padding()
        .background(Theme.sand.ignoresSafeArea())
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            if sortedPhotos.isEmpty {
                Text("No photos yet. Your first aligned shot starts the record.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedPhotos.reversed()) { photo in
                    HStack(spacing: 12) {
                        if let image = UIImage(data: photo.imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.medium))
                            HStack(spacing: 6) {
                                Image(systemName: photo.passedLightGuard ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(photo.passedLightGuard ? Theme.sage : Theme.flame)
                                Text("Light guard \(photo.passedLightGuard ? "passed" : "flagged")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let report = reportForPhoto(photo) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(String(format: "%.1f", report.rednessPct))%")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                Text("redness")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func reportForPhoto(_ photo: ProgressPhoto) -> SkinReport? {
        sortedReports.first { Calendar.current.isDate($0.createdAt, inSameDayAs: photo.capturedAt) }
    }

    @MainActor
    private func renderShareCard() {
        guard let before = sortedPhotos.first, let after = sortedPhotos.last,
              let afterImage = UIImage(data: after.imageData) else { return }
        let streak = streaks.first?.current ?? 0
        let card = ShareCardView(
            photo: afterImage,
            weeks: max(1, Calendar.current.dateComponents([.weekOfMonth], from: before.capturedAt, to: after.capturedAt).weekOfMonth ?? 1),
            streak: streak,
            trend: sortedReports.count >= 2 ? changeText(rednessChange) : "First scan logged",
            isPositive: rednessChange < 0
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let image = renderer.uiImage, let data = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("skinstreak-proof-card.png")
        try? data.write(to: url)
        shareURL = url
    }

    private var rednessChange: Double {
        guard let baseline = sortedReports.first, let latest = sortedReports.last, baseline.rednessPct > 0 else { return 0 }
        return (latest.rednessPct - baseline.rednessPct) / baseline.rednessPct * 100
    }
}

struct BeforeAfterSlider: View {
    let before: ProgressPhoto
    let after: ProgressPhoto
    @State private var position: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            ZStack {
                if let afterImage = UIImage(data: after.imageData) {
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: geo.size.height)
                        .clipped()
                }
                if let beforeImage = UIImage(data: before.imageData) {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: geo.size.height)
                        .clipped()
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: width * position)
                        }
                }
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3)
                    .shadow(radius: 2)
                    .position(x: width * position, y: geo.size.height / 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.sageDeep)
                    )
                    .position(x: width * position, y: geo.size.height / 2)
                Text("Before")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5), in: Capsule())
                    .foregroundStyle(.white)
                    .position(x: 48, y: 24)
                Text("After")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5), in: Capsule())
                    .foregroundStyle(.white)
                    .position(x: width - 44, y: 24)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = min(1, max(0, value.location.x / width))
                    }
            )
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct ShareCardView: View {
    let photo: UIImage
    let weeks: Int
    let streak: Int
    let trend: String
    let isPositive: Bool

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Theme.flame)
                Text("SkinStreak")
                    .font(.title3.weight(.bold))
                Spacer()
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.flame)
            }
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(height: 330)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            VStack(spacing: 6) {
                Text("\(weeks) week\(weeks == 1 ? "" : "s") of proof")
                    .font(.title2.weight(.bold))
                Text(trend)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isPositive ? Theme.sageDeep : Theme.flame)
                Text("measured on-device — not a beauty score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("proven by SkinStreak")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.sageDeep)
        }
        .padding(24)
        .frame(width: 360, height: 640)
        .background(Theme.sand)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}
