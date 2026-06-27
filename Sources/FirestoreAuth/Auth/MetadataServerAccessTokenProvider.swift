import Foundation
import FirestoreAuthCore
import FirestoreCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor MetadataServerAccessTokenProvider: AccessTokenProvider {
    public nonisolated let scope: any AccessScope

    private let metadataBaseURL: URL
    private let tokenRequester: MetadataTokenRequester
    private let now: @Sendable () -> Date
    private var cachedToken: CachedToken?
    private var inFlightToken: Task<CachedToken, Error>?

    public init(
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) throws {
        guard let metadataBaseURL = URL(string: "http://metadata.google.internal/computeMetadata/v1") else {
            throw FirestoreError.invalidConfiguration("Default metadata server endpoint is not a valid URL.")
        }
        self.init(
            scope: scope,
            metadataBaseURL: metadataBaseURL,
            tokenRequester: Self.defaultTokenRequester,
            now: { Date() }
        )
    }

    init(
        scope: any AccessScope = FirestoreAccessScope.datastore,
        metadataBaseURL: URL,
        tokenRequester: @escaping MetadataTokenRequester,
        now: @escaping @Sendable () -> Date
    ) {
        self.scope = scope
        self.metadataBaseURL = metadataBaseURL
        self.tokenRequester = tokenRequester
        self.now = now
    }

    public func getAccessToken(expirationDuration: TimeInterval) async throws -> String {
        let currentDate = now()
        if let cachedToken, cachedToken.expiration.timeIntervalSince(currentDate) > 60 {
            return cachedToken.value
        }

        if let inFlightToken {
            return try await inFlightToken.value.value
        }

        let request = try makeTokenRequest()
        let requester = tokenRequester
        let requestDate = currentDate
        let requestTask = Task { () throws -> CachedToken in
            let response = try await requester(request)
            guard !response.accessToken.isEmpty else {
                throw FirestoreError.invalidAccessToken("Metadata server token response did not include an access token.")
            }
            guard response.expiresIn > 0 else {
                throw FirestoreError.invalidAccessToken("Metadata server token response did not include a valid expiration.")
            }
            if let tokenType = response.tokenType, tokenType.caseInsensitiveCompare("Bearer") != .orderedSame {
                throw FirestoreError.invalidAccessToken(
                    "Metadata server token response returned unsupported token type \(tokenType)."
                )
            }
            return CachedToken(
                value: response.accessToken,
                expiration: requestDate.addingTimeInterval(response.expiresIn)
            )
        }

        inFlightToken = requestTask
        do {
            let token = try await requestTask.value
            cachedToken = token
            inFlightToken = nil
            return token.value
        } catch {
            inFlightToken = nil
            throw error
        }
    }

    private func makeTokenRequest() throws -> URLRequest {
        let tokenURL = try metadataURL(
            path: "instance/service-accounts/default/token"
        )
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "GET"
        request.addValue("Google", forHTTPHeaderField: "Metadata-Flavor")
        return request
    }

    private func metadataURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        let url = metadataBaseURL.appendingPathComponent(path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw FirestoreError.invalidConfiguration("Metadata server endpoint is not a valid URL.")
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw FirestoreError.invalidConfiguration("Metadata server endpoint is not a valid URL.")
        }
        return url
    }

    private static func defaultTokenRequester(_ request: URLRequest) async throws -> MetadataTokenResponse {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FirestoreError.invalidAccessToken("Metadata server returned a non-HTTP response.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw FirestoreError.invalidAccessToken(
                "Metadata server token request failed with HTTP \(httpResponse.statusCode). \(responseBody)"
            )
        }
        return try JSONDecoder().decode(MetadataTokenResponse.self, from: data)
    }

    static var defaultTokenRequesterForADC: MetadataTokenRequester {
        Self.defaultTokenRequester
    }

    typealias MetadataTokenRequester = @Sendable (URLRequest) async throws -> MetadataTokenResponse

    struct MetadataTokenResponse: Decodable, Sendable {
        let accessToken: String
        let expiresIn: TimeInterval
        let tokenType: String?

        private enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case tokenType = "token_type"
        }
    }

    private struct CachedToken: Sendable {
        let value: String
        let expiration: Date
    }
}
