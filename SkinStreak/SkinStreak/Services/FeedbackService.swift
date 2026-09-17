import Foundation

nonisolated struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}

nonisolated struct FeedbackResponse: Decodable {
    let success: Bool?
    let id: Int?
    let error: String?
}

nonisolated enum FeedbackError: LocalizedError {
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .server(let message): message
        case .badResponse: "Something went wrong. Please try again."
        }
    }
}

enum FeedbackService {
    static let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev")!

    static func send(_ request: FeedbackRequest) async throws {
        var urlRequest = URLRequest(url: backendURL.appendingPathComponent("api/feedback"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw FeedbackError.badResponse }
        let decoded = try? JSONDecoder().decode(FeedbackResponse.self, from: data)
        guard (200...299).contains(http.statusCode) else {
            throw FeedbackError.server(decoded?.error ?? "Something went wrong. Please try again.")
        }
    }
}
