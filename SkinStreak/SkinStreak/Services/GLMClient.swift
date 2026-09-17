import Foundation

nonisolated struct GLMChoice: Decodable {
    let message: GLMMessage
}

nonisolated struct GLMMessage: Decodable {
    let content: String?
}

nonisolated struct GLMResponse: Decodable {
    let choices: [GLMChoice]?
}

nonisolated enum GLMError: LocalizedError {
    case missingKey
    case badStatus(Int)
    case emptyContent

    var errorDescription: String? {
        switch self {
        case .missingKey: "No API key configured. Add your key in Settings."
        case .badStatus(let code): "AI request failed (status \(code)). Check your key and connection."
        case .emptyContent: "The AI returned no content. Please try again."
        }
    }
}

nonisolated enum GLMClient {
    static let endpoint = URL(string: "https://api.z.ai/api/paas/v4/chat/completions")!
    static let modelID = "glm-5.3-flash"

    static var hasKey: Bool { !GLMKeyStore.apiKey.isEmpty }

    static func testKey() async throws -> String {
        try await chat(system: "You are a connection health check.", user: "Reply with exactly: OK", imageBase64: nil, jsonMode: false)
    }

    static func chatJSON(system: String, user: String, imageBase64: String? = nil) async throws -> String {
        try await chat(system: system, user: user, imageBase64: imageBase64, jsonMode: true)
    }

    private static func chat(system: String, user: String, imageBase64: String?, jsonMode: Bool) async throws -> String {
        let key = GLMKeyStore.apiKey
        guard !key.isEmpty else { throw GLMError.missingKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        var userContent: Any = user
        if let imageBase64, !imageBase64.isEmpty {
            userContent = [
                ["type": "text", "text": user],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
            ]
        }

        var body: [String: Any] = [
            "model": modelID,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": userContent]
            ],
            "temperature": 0.4,
            "max_tokens": 2048
        ]
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GLMError.badStatus((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        let decoded = try JSONDecoder().decode(GLMResponse.self, from: data)
        guard let content = decoded.choices?.first?.message.content, !content.isEmpty else {
            throw GLMError.emptyContent
        }
        return content
    }
}
