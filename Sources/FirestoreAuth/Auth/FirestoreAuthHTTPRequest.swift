import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FirestoreAuthHTTPRequest: Sendable {
    let url: URL
    var httpMethod: String?
    var httpBody: Data?

    private var headerFields: [String: String]

    init(url: URL) {
        self.url = url
        self.httpMethod = nil
        self.httpBody = nil
        self.headerFields = [:]
    }

    mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        headerFields[field] = value
    }

    func value(forHTTPHeaderField field: String) -> String? {
        headerFields[field]
    }
}

#if canImport(FoundationNetworking) || canImport(Darwin)
extension FirestoreAuthHTTPRequest {
    func urlRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.httpBody = httpBody
        for (field, value) in headerFields {
            request.addValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
#endif
