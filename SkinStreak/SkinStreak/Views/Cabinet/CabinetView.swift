import SwiftData
import SwiftUI

struct CabinetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var products: [Product]

    @State private var showScan = false

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.sage.opacity(0.6))
                        Text("Add your first product — conflict check takes 0.3 seconds.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            showScan = true
                        } label: {
                            Label("Scan a product", systemImage: "barcode")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(products) { product in
                            ProductRow(product: product)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(products[index])
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Cabinet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add a product")
                }
            }
            .sheet(isPresented: $showScan) {
                ScanView()
            }
        }
    }
}

private struct ProductRow: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(product.name)
                    .font(.headline)
                Spacer()
                if !product.avoidSession.isEmpty {
                    Label(product.avoidSession, systemImage: "arrow.triangle.swap")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.sageDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.sage.opacity(0.14), in: Capsule())
                }
            }
            if !product.brand.isEmpty {
                Text(product.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !product.actives.isEmpty {
                HStack(spacing: 6) {
                    ForEach(product.actives, id: \.self) { active in
                        ActiveChip(name: active)
                    }
                }
            }
            if !product.avoidNote.isEmpty {
                Text(product.avoidNote)
                    .font(.caption2)
                    .foregroundStyle(Theme.coral)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
