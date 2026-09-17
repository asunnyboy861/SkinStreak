import Foundation

nonisolated struct OBFProduct: Identifiable, Equatable, Codable {
    var id: String { barcode.isEmpty ? name : barcode }
    var name: String
    var brand: String
    var barcode: String
    var ingredientsText: String
}

nonisolated struct OBFProductPayload: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let ingredients: [OBFIngredient]?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case ingredientsText = "ingredients_text"
        case ingredients
    }
}

nonisolated struct OBFIngredient: Decodable {
    let text: String?
}

nonisolated struct OBFProductResponse: Decodable {
    let status: Int?
    let product: OBFProductPayload?
}

nonisolated struct OBFSearchResponse: Decodable {
    let products: [OBFProductPayload]?
}

final class OBFApiClient {
    static let shared = OBFApiClient()
    private let session = URLSession(configuration: .ephemeral)

    private var cacheDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("obf_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    func fetchProduct(barcode: String) async -> OBFProduct? {
        if let cached = readCache(barcode: barcode) { return cached }
        let urlString = "https://world.openbeautyfacts.org/api/v2/product/\(barcode).json?fields=code,product_name,brands,ingredients_text,ingredients"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(OBFProductResponse.self, from: data)
            guard response.status == 1, let payload = response.product else { return nil }
            let product = product(from: payload, fallbackBarcode: barcode)
            writeCache(product, barcode: barcode)
            return product
        } catch {
            return nil
        }
    }

    func searchProducts(query: String) async -> [OBFProduct] {
        let terms = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://world.openbeautyfacts.org/cgi/search.pl?search_terms=\(terms)&search_simple=1&action=process&json=1&page_size=10&fields=code,product_name,brands,ingredients_text,ingredients"
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(OBFSearchResponse.self, from: data)
            return (response.products ?? []).compactMap { payload in
                let product = product(from: payload, fallbackBarcode: payload.code ?? "")
                guard !product.name.isEmpty else { return nil }
                return product
            }
        } catch {
            return []
        }
    }

    private func product(from payload: OBFProductPayload, fallbackBarcode: String) -> OBFProduct {
        var ingredientText = payload.ingredientsText ?? ""
        if ingredientText.isEmpty, let list = payload.ingredients {
            ingredientText = list.compactMap { $0.text }.joined(separator: ", ")
        }
        return OBFProduct(
            name: payload.productName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            brand: payload.brands ?? "",
            barcode: payload.code ?? fallbackBarcode,
            ingredientsText: ingredientText
        )
    }

    private func cacheURL(for barcode: String) -> URL {
        cacheDirectory.appendingPathComponent("obf_\(barcode).json")
    }

    private func readCache(barcode: String) -> OBFProduct? {
        guard let data = try? Data(contentsOf: cacheURL(for: barcode)),
              let product = try? JSONDecoder().decode(OBFProduct.self, from: data) else { return nil }
        return product
    }

    private func writeCache(_ product: OBFProduct, barcode: String) {
        guard let data = try? JSONEncoder().encode(product) else { return }
        try? data.write(to: cacheURL(for: barcode), options: .atomic)
    }
}
