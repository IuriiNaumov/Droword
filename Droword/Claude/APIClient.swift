import Foundation

enum APIError: LocalizedError {
    case noConnection
    case timeout
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return String(localized: "No internet connection")
        case .timeout:
            return String(localized: "Request timed out. Please try again.")
        case .serverError(_, let message):
            return message
        }
    }
}

enum APIClient {
    static let baseURL = "https://droword-api.droword-api.workers.dev"

    /// App key decoded at runtime via XOR to avoid plain-text in the binary.
    static var appKey: String {
        let encoded: [UInt8] = [
            0xC3, 0xD5, 0xD0, 0xF8, 0xCB, 0xCE, 0xD1, 0xC2,
            0xF8, 0x95, 0x9F, 0xC1, 0x9E, 0xC6, 0x96, 0xC4,
            0x90, 0xC2, 0x92, 0xC3, 0x94, 0x93, 0xC5, 0x91
        ]
        let mask: UInt8 = 0xA7
        return String(bytes: encoded.map { $0 ^ mask }, encoding: .utf8) ?? ""
    }

    static func makeRequest(endpoint: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(appKey, forHTTPHeaderField: "X-App-Key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func validateResponse(_ data: Data, _ response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: http.statusCode, message: message)
        }
        return data
    }

    /// Performs the request with automatic timeout/connectivity error mapping.
    static func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw APIError.noConnection
            case .timedOut:
                throw APIError.timeout
            default:
                throw error
            }
        }
    }
}
