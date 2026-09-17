import SwiftData
import SwiftUI

struct ScanView: View {
    var onFirstProductAdded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]

    @State private var scanner = BarcodeScannerController()
    @State private var phase: Phase = .scanning
    @State private var resultProduct: OBFProduct?
    @State private var showResult = false
    @State private var showManual = false
    @State private var pendingFindings: [ConflictFinding] = []
    @State private var showConflict = false
    @State private var showSuccess = false
    @State private var successCopy = ""

    enum Phase: Equatable {
        case scanning
        case lookingUp(String)
        case notFound(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreviewView(session: scanner.session)
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.sage, lineWidth: 3)
                        .frame(width: 260, height: 160)
                        .accessibilityHidden(true)
                    Spacer()
                    statusFooter
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    scanner.stop()
                    showManual = true
                } label: {
                    Label("Enter manually", systemImage: "pencil.line")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .task {
            scanner.configureAndStart()
        }
        .onDisappear {
            scanner.stop()
        }
        .onChange(of: scanner.detectedCode) {
            if let code = scanner.detectedCode, phase == .scanning {
                lookup(code)
            }
        }
        .sheet(isPresented: $showManual) {
            ManualEntryView { name, brand, ingredients in
                addProduct(name: name, brand: brand, barcode: "", ingredientsRaw: ingredients)
            }
        }
        .sheet(isPresented: $showResult) {
            if let product = resultProduct {
                ProductResultView(product: product) { name, brand, barcode, ingredients in
                    addProduct(name: name, brand: brand, barcode: barcode, ingredientsRaw: ingredients)
                }
                .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showConflict) {
            ConflictAlertView(findings: pendingFindings) { finding in
                if let added = lastAdded {
                    separate(finding, product: added)
                }
                advanceConflict()
            } onUseAnyway: { finding in
                modelContext.insert(ConflictLog(
                    ruleID: finding.rule.id,
                    productA: finding.productAName,
                    productB: finding.productBName,
                    severity: finding.rule.severity,
                    resolution: "dismissed"
                ))
                advanceConflict()
            }
            .presentationDetents([.medium, .fraction(0.62)])
        }
        .sheet(isPresented: $showSuccess) {
            successSheet
        }
    }

    @State private var lastAdded: Product?

    private var statusFooter: some View {
        VStack(spacing: 8) {
            switch phase {
            case .scanning:
                Label("Point the camera at the barcode on the pack", systemImage: "barcode.viewfinder")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.55), in: Capsule())
            case .lookingUp(let code):
                HStack(spacing: 10) {
                    ProgressView().tint(.white)
                    Text("Looking up \(code)").font(.subheadline).foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.55), in: Capsule())
            case .notFound:
                VStack(spacing: 10) {
                    Text("No match for this barcode.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Button("Try again") {
                        scanner.detectedCode = nil
                        phase = .scanning
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private var successSheet: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.sage)
            Text(successCopy)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text(Theme.disclaimer)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .presentationDetents([.fraction(0.42)])
    }

    private func lookup(_ code: String) {
        phase = .lookingUp(code)
        Task {
            let product = await OBFApiClient.shared.fetchProduct(barcode: code)
            if let product, !product.ingredientsText.isEmpty {
                resultProduct = product
                showResult = true
                phase = .scanning
            } else {
                phase = .notFound(code)
                scanner.detectedCode = nil
            }
        }
    }

    private func addProduct(name: String, brand: String, barcode: String, ingredientsRaw: String) {
        let product = Product(
            name: name,
            brand: brand,
            barcode: barcode,
            ingredientsRaw: ingredientsRaw,
            actives: IngredientParser.recognizedActives(from: ingredientsRaw)
        )
        modelContext.insert(product)
        lastAdded = product

        let cabinet = products.filter { $0.name != product.name }
        let findings = ConflictEngine.check(product: product, cabinet: cabinet)
        if findings.isEmpty {
            successCopy = "Added to cabinet — no conflicts found."
            onFirstProductAdded?()
            showSuccess = true
        } else {
            pendingFindings = findings
            showConflict = true
        }
    }

    private func separate(_ finding: ConflictFinding, product: Product) {
        let families = ConflictEngine.families(in: product.actives)
        let morningType = families.contains("bpo") || families.contains("sulfur") || families.contains("vitc")
        product.avoidSession = morningType ? "AM" : "PM"
        product.avoidNote = finding.rule.resolution
        modelContext.insert(ConflictLog(
            ruleID: finding.rule.id,
            productA: finding.productAName,
            productB: finding.productBName,
            severity: finding.rule.severity,
            resolution: "separated"
        ))
    }

    private func advanceConflict() {
        if pendingFindings.count > 1 {
            pendingFindings.removeFirst()
        } else {
            showConflict = false
            successCopy = "Sorted — tonight's plan updated."
            onFirstProductAdded?()
            showSuccess = true
        }
    }
}

struct ProductResultView: View {
    let product: OBFProduct
    let onAdd: (String, String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    private var ingredients: [String] {
        IngredientParser.normalize(product.ingredientsText)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.name)
                            .font(.title3.bold())
                        if !product.brand.isEmpty {
                            Text(product.brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if !product.barcode.isEmpty {
                            Text(product.barcode)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if !IngredientParser.recognizedActives(from: product.ingredientsText).isEmpty {
                        activeBadges
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ingredients (INCI)")
                            .font(.headline)
                        ForEach(ingredients, id: \.self) { ingredient in
                            HStack(spacing: 8) {
                                Text(IngredientParser.displayName(for: ingredient))
                                    .font(.subheadline)
                                if IngredientParser.isKnownActive(ingredient) {
                                    ActiveChip(name: "active")
                                }
                                Spacer()
                            }
                            .padding(.vertical, 3)
                        }
                    }

                    Text(Theme.disclaimer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button {
                        onAdd(product.name, product.brand, product.barcode, product.ingredientsText)
                        dismiss()
                    } label: {
                        Label("Add to Cabinet", systemImage: "shippingbox.and.arrow.backward")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(20)
            }
            .background(Theme.sand.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private var activeBadges: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recognized actives")
                .font(.headline)
            HStack(spacing: 6) {
                ForEach(IngredientParser.recognizedActives(from: product.ingredientsText), id: \.self) { active in
                    ActiveChip(name: active)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.sage.opacity(0.1)))
    }
}

struct ManualEntryView: View {
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var brand = ""
    @State private var ingredients = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Product name", text: $name)
                    TextField("Brand (optional)", text: $brand)
                }
                Section {
                    TextEditor(text: $ingredients)
                        .frame(minHeight: 120)
                        .accessibilityLabel("Ingredient list")
                } header: {
                    Text("Ingredient list (INCI)")
                } footer: {
                    Text("Paste the ingredient list from the pack. SkinStreak normalizes it and highlights recognized actives.")
                }
            }
            .navigationTitle("Manual entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(name, brand, ingredients)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
