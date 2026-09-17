import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile

    @State private var step = 0
    @State private var showScan = false
    @State private var addedFirstProduct = false

    private let skinTypes = ["Oily", "Dry", "Combination", "Sensitive"]
    private let goals = ["Clear acne", "Even tone", "Calm redness", "Smooth texture", "General glow"]
    private let fitzpatrickCards: [(grade: Int, title: String, detail: String)] = [
        (1, "Type I", "Very fair skin, always burns, never tans"),
        (2, "Type II", "Fair skin, burns easily, tans with difficulty"),
        (3, "Type III", "Medium skin, sometimes burns, tans gradually"),
        (4, "Type IV", "Olive or light brown skin, rarely burns, tans easily"),
        (5, "Type V", "Brown skin, very rarely burns, tans dark easily"),
        (6, "Type VI", "Deep brown skin, never burns")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? Theme.sage : Theme.sage.opacity(0.25))
                            .frame(width: index == step ? 24 : 10, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: step)
                    }
                }
                .padding(.top, 12)

                TabView(selection: $step) {
                    valueProp.tag(0)
                    skinTypeStep.tag(1)
                    fitzpatrickStep.tag(2)
                    firstProductStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 8)
            }
            .background(Theme.sand.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if (1...2).contains(step) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Next") {
                            withAnimation { step += 1 }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showScan) {
            ScanView(onFirstProductAdded: { addedFirstProduct = true })
        }
    }

    private var valueProp: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.flame)
                .accessibilityHidden(true)
            Text("Skincare that proves it works.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 12) {
                Label("Free conflict engine — catches Retinol × Benzoyl Peroxide in 0.1 seconds", systemImage: "shield.checkered")
                Label("Streaks with Streak Freeze — never shames, never resets to zero", systemImage: "snowflake")
                Label("Aligned proof photos with trend % — never beauty scores", systemImage: "chart.line.uptrend.xyaxis")
            }
            .font(.subheadline)
            .padding(.horizontal, 28)
            Spacer()
            Text("Pro from $3.99/mo · 7-day free trial · cancel anytime")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private var skinTypeStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What's your skin like?")
                    .font(.title.bold())
                VStack(spacing: 10) {
                    ForEach(skinTypes, id: \.self) { type in
                        Button {
                            profile.skinType = type
                        } label: {
                            HStack {
                                Text(type)
                                Spacer()
                                if profile.skinType == type {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.sage)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(profile.skinType == type ? Theme.sage.opacity(0.14) : Theme.card)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(profile.skinType == type ? Theme.sage : Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("What's the goal?")
                    .font(.title3.bold())
                    .padding(.top, 8)
                Menu {
                    ForEach(goals, id: \.self) { goal in
                        Button(goal) { profile.goal = goal }
                    }
                } label: {
                    HStack {
                        Text(profile.goal)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.card))
                }
            }
            .padding(24)
        }
    }

    private var fitzpatrickStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pick your Fitzpatrick type")
                    .font(.title.bold())
                Text("This calibrates your measured metrics. It's never a score.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(spacing: 10) {
                    ForEach(fitzpatrickCards, id: \.grade) { card in
                        Button {
                            profile.fitzpatrick = card.grade
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Theme.sage.opacity(0.2 + Double(card.grade) * 0.13))
                                    .frame(width: 34, height: 34)
                                    .overlay(Text("\(card.grade)").font(.caption.bold()))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.title).font(.subheadline.weight(.semibold))
                                    Text(card.detail).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if profile.fitzpatrick == card.grade {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.sage)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(profile.fitzpatrick == card.grade ? Theme.sage.opacity(0.14) : Theme.card)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
    }

    private var firstProductStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(Theme.sage)
            Text("Scan one product to set up tonight")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("The camera only reads the barcode and the analysis happens on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button {
                showScan = true
            } label: {
                Label(addedFirstProduct ? "Scan another" : "Scan a product", systemImage: "barcode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            Spacer()
            Button {
                finish()
            } label: {
                Text(addedFirstProduct ? "Go to Tonight" : "Skip — add later")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.bottom, 28)
        }
    }

    private func finish() {
        profile.onboardingCompleted = true
        profile.cyclingStartedAt = Date()
        Task {
            if await NotificationScheduler.requestAuthorization() {
                NotificationScheduler.scheduleSundayReminder()
            }
        }
    }
}
