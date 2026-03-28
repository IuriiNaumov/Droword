import Foundation

enum APIClient {
    static let baseURL = "https://droword-api.droword-api.workers.dev"
    static let appKey = "drw_live_28f9a1c7e5d34b6"

    static func makeRequest(endpoint: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
            throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return data
    }
}
