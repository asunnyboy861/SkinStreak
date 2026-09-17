import SwiftData
import SwiftUI
import UIKit

struct CaptureOutcome: Identifiable {
    let id = UUID()
    let report: SkinReport
    let photoData: Data
    let fitzpatrick: Int
    let cabinet: [Product]
}

struct GuidedCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var photos: [ProgressPhoto]
    @Query private var reports: [SkinReport]
    @Query private var products: [Product]
    @StateObject private var camera = CameraController()
    @State private var outcome: CaptureOutcome?
    @State private var isProcessing = false
    @State private var lightWarning: LightGuardStatus?

    private var profile: UserProfile? { profiles.first }
    private var lastPhoto: ProgressPhoto? { photos.max { $0.capturedAt < $1.capturedAt } }

    var body: some View {
        ZStack {
            CameraPreviewView(session: camera.session)
                .ignoresSafeArea()
            VStack {
                topBar
                lightBanner
                Spacer()
                alignmentOverlay
                Spacer()
                brightnessBar
                controls
            }
        }
        .onAppear {
            camera.onPhotoCaptured = { handleCapture($0) }
            camera.configureAndStart()
        }
        .onDisappear {
            camera.stop()
        }
        .fullScreenCover(item: $outcome) { value in
            CaptureResultView(outcome: value)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.35), in: Circle())
            }
            Spacer()
            Text("Weekly photo")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal)
    }

    private var lightBanner: some View {
        let status = lightWarning ?? camera.lightStatus
        return HStack(spacing: 8) {
            Image(systemName: status.icon)
            Text(status.banner)
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(status.isPass ? Color.white : Theme.flame)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background((status.isPass ? Color.black.opacity(0.4) : Theme.flame.opacity(0.9)).clipShape(Capsule()))
        .padding(.top, 10)
    }

    private var alignmentOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.72
            let h = geo.size.width * 0.92
            ZStack {
                if let lastPhoto, let ghost = UIImage(data: lastPhoto.imageData) {
                    Image(uiImage: ghost)
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h)
                        .clipShape(Ellipse())
                        .opacity(0.3)
                        .allowsHitTesting(false)
                }
                Ellipse()
                    .stroke(Color.white.opacity(0.9), lineWidth: 3)
                    .frame(width: w, height: h)
                VStack(spacing: 4) {
                    Text("Line up with your last photo")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                    if lastPhoto != nil {
                        Text("Ghost image shows your previous shot at 30%")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .position(x: geo.size.width / 2, y: h + 24)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 380)
    }

    private var brightnessBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(height: 6)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geo.size.width * 0.243, height: 10)
                        .overlay(alignment: .trailing) { Color.white.frame(width: 1.5) }
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geo.size.width * 0.729, height: 10)
                        .overlay(alignment: .leading) { Color.white.frame(width: 1.5) }
                    Circle()
                        .fill(Theme.flame)
                        .frame(width: 12, height: 12)
                        .offset(x: min(max(0, geo.size.width * camera.meanLuma / 255 - 6), geo.size.width - 12))
                }
            }
            .frame(height: 12)
            Text("Brightness \(Int(camera.meanLuma))")
                .font(.caption2.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 40)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                guard !isProcessing else { return }
                isProcessing = true
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 78, height: 78)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 62, height: 62)
                    if isProcessing {
                        ProgressView()
                    }
                }
            }
            .disabled(isProcessing || !camera.isRunning)
            if !camera.isRunning {
                Text("Camera unavailable — check permission in Settings.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                #if targetEnvironment(simulator)
                Button("Simulator demo capture") {
                    handleCapture(Self.demoPhotoData())
                }
                .buttonStyle(.borderedProminent)
                #endif
            }
        }
        .padding(.bottom, 30)
    }

    private func handleCapture(_ data: Data) {
        guard let profile, !isProcessing else { return }
        let luma = LightGuard.meanLuma(fromImageData: data)
        let baseline = lastPhoto.flatMap { $0.passedLightGuard ? $0.meanLuma : nil }
        let status = LightGuard.evaluate(meanLuma: luma, baseline: baseline)
        guard status.isPass else {
            lightWarning = status
            isProcessing = false
            Haptics.warning()
            return
        }
        guard let metrics = CVPipeline.analyze(imageData: data, fitzpatrick: profile.fitzpatrick) else {
            lightWarning = .tooDark
            isProcessing = false
            return
        }
        lightWarning = nil
        let savedData = UIImage(data: data)?.jpegData(compressionQuality: 0.85) ?? data
        let previous = reports.sorted { $0.createdAt < $1.createdAt }.last
        let photo = ProgressPhoto(imageData: savedData, meanLuma: luma, passedLightGuard: true)
        let report = SkinReport(
            createdAt: Date(),
            rednessPct: metrics.rednessPct,
            textureVar: metrics.textureVar,
            spotCount: metrics.spotCount
        )
        modelContext.insert(photo)
        modelContext.insert(report)
        let cabinet = products
        let fitz = profile.fitzpatrick
        Task {
            let coach = await AIRouter.dailyCoachNote(metrics: metrics, previous: previous, fitzpatrick: fitz)
            report.coachNote = coach.note
            report.noteSource = coach.label == "AI insight" ? "ai" : "template"
            outcome = CaptureOutcome(report: report, photoData: savedData, fitzpatrick: fitz, cabinet: cabinet)
            isProcessing = false
            Haptics.success()
        }
    }

    #if targetEnvironment(simulator)
    nonisolated static func demoPhotoData() -> Data {
        let size = CGSize(width: 900, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let colors = [UIColor(red: 0.87, green: 0.72, blue: 0.62, alpha: 1).cgColor,
                          UIColor(red: 0.78, green: 0.60, blue: 0.50, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            ctx.cgContext.setFillColor(UIColor(red: 0.83, green: 0.67, blue: 0.57, alpha: 1).cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 180, y: 200, width: 540, height: 720))
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
    #endif
}

struct CaptureResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var quota = QuotaManager.shared
    let outcome: CaptureOutcome

    @State private var deepResult: DeepScanResult?
    @State private var isDeepScanning = false
    @State private var showUploadConfirm = false
    @State private var showPaywall = false

    private var report: SkinReport { outcome.report }
    private var noteLabel: String { report.noteSource == "ai" ? "AI insight" : "Coach note" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoHeader
                    measurementsCard
                    coachCard
                    deepScanCard
                    if let deepResult {
                        deepResultSections(deepResult)
                    }
                    Text(Theme.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Theme.sand.ignoresSafeArea())
            .navigationTitle("Scan saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Upload this one photo?", isPresented: $showUploadConfirm, titleVisibility: .visible) {
                Button("Upload") { runDeepScan() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The photo is sent to your own AI key for a deeper read, then discarded. SkinStreak never stores uploads.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var photoHeader: some View {
        Group {
            if let image = UIImage(data: outcome.photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private var measurementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's measurements")
                    .font(.headline)
                Spacer()
                Text("measured")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.sage.opacity(0.16), in: Capsule())
                    .foregroundStyle(Theme.sageDeep)
            }
            metricRow("Redness", String(format: "%.1f%%", report.rednessPct))
            metricRow("Texture variance", String(format: "%.2f", report.textureVar))
            metricRow("Visible spots", "\(report.spotCount)")
            Text("Compared only to your own baseline — never a beauty score.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(noteLabel, systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.sageDeep)
            Text(report.coachNote)
                .font(.subheadline)
            Text(Theme.disclaimer)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var deepScanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Deep scan")
                    .font(.headline)
                Spacer()
                if entitlements.isPro {
                    Text("Unlimited")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.sageDeep)
                } else {
                    HStack(spacing: 5) {
                        ForEach(0..<QuotaManager.weeklyFreeLimit, id: \.self) { index in
                            Circle()
                                .fill(index < quota.remainingDeepScans(isPro: false) ? Theme.sage : Theme.sage.opacity(0.25))
                                .frame(width: 9, height: 9)
                        }
                    }
                    Text("left this week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(deepResult == nil
                 ? "One deeper read of this photo — on-device with Apple Intelligence, or through your own AI key."
                 : "Deep scan complete. Results below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                if quota.canDeepScan(isPro: entitlements.isPro) {
                    showUploadConfirm = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    if isDeepScanning {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(deepResult == nil ? "Deep scan this photo" : "Deep scan again")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDeepScanning)
            if !GLMClient.hasKey && !entitlements.isPro {
                Text("No key yet? Deep scans fall back to Apple Intelligence or the template coach — nothing dead-ends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func deepResultSections(_ result: DeepScanResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result.label, systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.sageDeep)
            Text(result.report.summary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        VStack(alignment: .leading, spacing: 12) {
            Text("Observations")
                .font(.headline)
            ForEach(result.report.observations) { observation in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(observation.zone)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        EvidenceGradeBadge(grade: observation.evidenceGrade)
                    }
                    Text(observation.finding)
                        .font(.subheadline)
                    Text(observation.source)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

        if let adjustment = result.report.routineAdjustment {
            VStack(alignment: .leading, spacing: 8) {
                Label("Routine adjustment", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.sageDeep)
                if let name = adjustment.productName, !name.isEmpty {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                }
                if let action = adjustment.action, !action.isEmpty {
                    Text(action)
                        .font(.subheadline)
                }
                if let reason = adjustment.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }

        if let dropped = result.adjustmentDroppedReason {
            Label(dropped, systemImage: "shield.checkered")
                .font(.caption)
                .foregroundStyle(Theme.flame)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.flame.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func runDeepScan() {
        isDeepScanning = true
        let cabinet = outcome.cabinet
        let fitz = outcome.fitzpatrick
        let photoData = outcome.photoData
        Task {
            let result = await AIRouter.deepScan(imageData: photoData, metrics: SkinMetrics(
                rednessPct: report.rednessPct,
                textureVar: report.textureVar,
                spotCount: report.spotCount
            ), fitzpatrick: fitz, cabinet: cabinet)
            report.isDeep = true
            report.deepUsedGLM = result.usedGLM
            report.deepSummary = result.report.summary
            if let payload = try? JSONEncoder().encode(result.report), let text = String(data: payload, encoding: .utf8) {
                report.deepPayload = text
            }
            quota.recordDeepScan()
            deepResult = result
            isDeepScanning = false
            Haptics.success()
        }
    }
}
