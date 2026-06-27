import Crypto
import CryptoExtras
import Foundation
import FirestoreAuthCore
import FirestoreCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor ServiceAccountAccessTokenProvider: AccessTokenProvider {
    public nonisolated let scope: any AccessScope

    private let credentials: ServiceAccountCredentials
    private let privateKey: _RSA.Signing.PrivateKey
    private let tokenRequester: @Sendable (URL, Data) async throws -> OAuthTokenResponse
    private let now: @Sendable () -> Date
    private var cachedToken: CachedToken?
    private var inFlightToken: Task<CachedToken, Error>?

    public init(
        credentials: ServiceAccountCredentials,
        scope: any AccessScope = FirestoreAccessScope.datastore
    ) throws {
        try self.init(
            credentials: credentials,
            scope: scope,
            tokenRequester: Self.defaultTokenRequester,
            now: { Date() }
        )
    }

    init(
        credentials: ServiceAccountCredentials,
        scope: any AccessScope = FirestoreAccessScope.datastore,
        tokenRequester: @escaping @Sendable (URL, Data) async throws -> OAuthTokenResponse,
        now: @escaping @Sendable () -> Date
    ) throws {
        self.credentials = credentials
        self.scope = scope
        self.privateKey = try _RSA.Signing.PrivateKey(pemRepresentation: credentials.privateKey)
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

        let assertion = try createAssertion(expirationDuration: expirationDuration, currentDate: currentDate)
        let body = try Self.formEncodedBody([
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": assertion
        ])
        let tokenRequester = tokenRequester
        let tokenURI = credentials.tokenURI
        let requestDate = currentDate
        let requestTask = Task { () throws -> CachedToken in
            let response = try await tokenRequester(tokenURI, body)
            guard !response.accessToken.isEmpty else {
                throw FirestoreError.invalidAccessToken("OAuth token response did not include an access token.")
            }
            guard response.expiresIn > 0 else {
                throw FirestoreError.invalidAccessToken("OAuth token response did not include a valid expiration.")
            }
            if let tokenType = response.tokenType, tokenType.caseInsensitiveCompare("Bearer") != .orderedSame {
                throw FirestoreError.invalidAccessToken("OAuth token response returned unsupported token type \(tokenType).")
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

    private func createAssertion(expirationDuration: TimeInterval, currentDate: Date) throws -> String {
        let issuedAt = Int(currentDate.timeIntervalSince1970)
        let lifetime = max(1, min(Int(expirationDuration), 3600))
        let expiresAt = issuedAt + lifetime

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let header = JWTHeader(alg: "RS256", typ: "JWT", kid: credentials.privateKeyId)
        let claims = JWTClaims(
            iss: credentials.clientEmail,
            scope: scope.value,
            aud: credentials.tokenURI.absoluteString,
            iat: issuedAt,
            exp: expiresAt
        )

        let headerSegment = try Self.base64URLEncode(encoder.encode(header))
        let claimsSegment = try Self.base64URLEncode(encoder.encode(claims))
        let signingInput = "\(headerSegment).\(claimsSegment)"
        let signature = try privateKey.signature(
            for: Data(signingInput.utf8),
            padding: .insecurePKCS1v1_5
        )
        let signatureSegment = try Self.base64URLEncode(signature.rawRepresentation)
        return "\(signingInput).\(signatureSegment)"
    }

    private static func defaultTokenRequester(tokenURI: URL, body: Data) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: tokenURI)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FirestoreError.invalidAccessToken("OAuth token endpoint returned a non-HTTP response.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw FirestoreError.invalidAccessToken(
                "OAuth token request failed with HTTP \(httpResponse.statusCode). \(responseBody)"
            )
        }

        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }

    static func formEncodedBody(_ values: [String: String]) throws -> Data {
        let pairs = try values
            .sorted { $0.key < $1.key }
            .map { key, value in
                let encodedKey = try percentEncode(key)
                let encodedValue = try percentEncode(value)
                return "\(encodedKey)=\(encodedValue)"
            }
        return Data(pairs.joined(separator: "&").utf8)
    }

    static func base64URLEncode(_ data: Data) throws -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func percentEncode(_ value: String) throws -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=?/")

        guard let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) else {
            throw FirestoreError.invalidConfiguration("Unable to encode OAuth token request.")
        }
        return encoded
    }

    struct OAuthTokenResponse: Decodable, Sendable {
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

    private struct JWTHeader: Encodable {
        let alg: String
        let typ: String
        let kid: String
    }

    private struct JWTClaims: Encodable {
        let iss: String
        let scope: String
        let aud: String
        let iat: Int
        let exp: Int
    }
}
