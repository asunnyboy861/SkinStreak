import SwiftData
import SwiftUI

struct TonightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]
    @Query private var profiles: [UserProfile]
    @Query private var allSlots: [RoutineSlot]
    @Query private var streakStates: [StreakState]
    @Query private var allCheckIns: [CheckIn]

    @State private var selectedSession = "PM"
    @State private var showScan = false
    @State private var banner: String?
    @State private var streakTrigger = 0
    @State private var didInitialBuild = false

    private var today: Date { StreakEngine.startOfDay(Date()) }
    private var cycleNight: SkinCycleNight {
        TonightEngine.cycleNight(for: Date(), startedAt: profiles.first?.cyclingStartedAt ?? Date())
    }
    private var sessionSlots: [RoutineSlot] {
        allSlots
            .filter { StreakEngine.isSameDay($0.day, today) && $0.session == selectedSession }
            .sorted { $0.order < $1.order }
    }
    private var allTodaySlots: [RoutineSlot] {
        allSlots.filter { StreakEngine.isSameDay($0.day, today) }
    }
    private var streak: StreakState? { streakStates.first }
    private var allDone: Bool {
        !allTodaySlots.isEmpty && allTodaySlots.allSatisfy { $0.status == "done" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakHeader
                    cycleBanner
                    if sessionSlots.isEmpty {
                        emptyState
                    } else {
                        ForEach(sessionSlots) { slot in
                            SlotCard(slot: slot) { complete(slot) }
                        }
                    }
                    if let banner {
                        Label(banner, systemImage: "sun.max.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.flame)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.flame.opacity(0.12)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.sand.ignoresSafeArea())
            .navigationTitle("Tonight")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScan = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                    .accessibilityLabel("Scan a product")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Picker("Session", selection: $selectedSession) {
                    Text("Morning").tag("AM")
                    Text("Tonight").tag("PM")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .sensoryFeedback(.success, trigger: streakTrigger)
            .sheet(isPresented: $showScan) {
                ScanView()
            }
            .task {
                guard streakStates.isEmpty else { return }
                modelContext.insert(StreakState())
            }
            .onAppear {
                rebuildSlots()
            }
            .onChange(of: products.count) {
                rebuildSlots()
            }
        }
    }

    private var streakHeader: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Theme.sage.opacity(0.2), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(Theme.flame, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.flame)
            }
            .frame(width: 74, height: 74)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak \(streak?.current ?? 0) days")

            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak?.current ?? 0) day streak")
                    .font(.title2.bold())
                HStack(spacing: 8) {
                    Label("\(streak?.longest ?? 0) best", systemImage: "trophy.fill")
                    Label("\(streak?.freezesLeft ?? 2) freezes", systemImage: "snowflake")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(cycleNight.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.sageDeep)
            }
            Spacer()
        }
        .padding()
        .glassCard()
    }

    private var progressValue: Double {
        guard !allTodaySlots.isEmpty else { return 0 }
        let done = allTodaySlots.filter { $0.status == "done" }.count
        return Double(done) / Double(allTodaySlots.count)
    }

    private var cycleBanner: some View {
        Label(cycleBannerCopy, systemImage: "moon.stars.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.sageDeep)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
    }

    private var cycleBannerCopy: String {
        switch cycleNight {
        case .exfoliation: return "Acids get the spotlight tonight — retinoids rest."
        case .retinoid: return "Retinoid night — skip acids and scrubs."
        case .recovery: return "Recovery night — barrier care only."
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundStyle(Theme.sage.opacity(0.6))
            Text("Add your first product — conflict check takes 0.3 seconds.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                showScan = true
            } label: {
                Label("Scan a product", systemImage: "barcode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .glassCard()
    }

    private func rebuildSlots() {
        let night = cycleNight
        let todaySlots = allTodaySlots
        let doneKeys = Set(todaySlots.filter { $0.status == "done" }.map { "\($0.session)|\($0.productName)" })
        for slot in todaySlots where slot.status != "done" {
            modelContext.delete(slot)
        }
        var existingKeys = doneKeys
        for session in ["AM", "PM"] {
            let plans = TonightEngine.buildSlots(for: today, session: session, cycleNight: night, products: products)
            for plan in plans {
                let key = "\(session)|\(plan.productName)"
                guard !existingKeys.contains(key) else { continue }
                modelContext.insert(RoutineSlot(
                    day: today,
                    session: session,
                    cycleNight: night.rawValue,
                    productName: plan.productName,
                    productActives: plan.actives,
                    isSeparated: plan.isSeparated,
                    separationNote: plan.note,
                    order: plan.order
                ))
                existingKeys.insert(key)
            }
        }
        _ = didInitialBuild
        didInitialBuild = true
    }

    private func complete(_ slot: RoutineSlot) {
        slot.status = "done"
        Haptics.success()

        let todaySlots = allTodaySlots
        let doneCount = todaySlots.filter { $0.status == "done" }.count
        let todayAllDone = !todaySlots.isEmpty && doneCount == todaySlots.count
        upsertCheckIn(completed: doneCount, total: todaySlots.count, allDone: todayAllDone)

        if todayAllDone, let state = streak {
            let outcome = StreakEngine.settle(state: state)
            switch outcome {
            case .continued(let streakValue):
                banner = "Streak day \(streakValue) — nice and steady."
            case .freezeUsed(let streakValue):
                banner = "Streak Freeze used — day \(streakValue) kept safe."
            case .restarted:
                banner = Theme.breakDayCopy
            }
            streakTrigger += 1
        }
    }

    private func upsertCheckIn(completed: Int, total: Int, allDone: Bool) {
        if let existing = allCheckIns.first(where: { StreakEngine.isSameDay($0.day, today) }) {
            existing.completedCount = completed
            existing.totalCount = total
            existing.allDone = allDone
        } else {
            modelContext.insert(CheckIn(day: today, completedCount: completed, totalCount: total, allDone: allDone))
        }
    }
}

private struct SlotCard: View {
    let slot: RoutineSlot
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: slot.status == "done" ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(slot.status == "done" ? Theme.sage : Color.secondary.opacity(0.5))
            VStack(alignment: .leading, spacing: 5) {
                Text(slot.productName)
                    .font(.headline)
                    .strikethrough(slot.status == "done")
                HStack(spacing: 6) {
                    ForEach(slot.productActives.prefix(3), id: \.self) { active in
                        ActiveChip(name: active)
                    }
                }
                if slot.isSeparated {
                    Label(slot.separationNote.isEmpty ? "Already separated" : slot.separationNote, systemImage: "arrow.triangle.swap")
                        .font(.caption2)
                        .foregroundStyle(Theme.sageDeep)
                        .lineLimit(2)
                }
            }
            Spacer()
            if slot.status != "done" {
                Button("Done", action: onComplete)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Theme.sage)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
