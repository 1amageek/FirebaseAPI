import CryptoExtras
import Foundation
import Testing
@testable import FirestoreAuth
@testable import FirestoreAPI

@Suite("Google Auth Tests")
struct GoogleAuthTests {
    @Test("Service account provider signs JWT assertion and caches token")
    func testServiceAccountProviderSignsAssertionAndCachesToken() async throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let credentials = try Self.makeCredentials(privateKey: privateKey)
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let requester = RecordingOAuthTokenRequester()
        let provider = try ServiceAccountAccessTokenProvider(
            credentials: credentials,
            scope: FirestoreAccessScope.datastore,
            tokenRequester: { tokenURI, body in
                try await requester.request(tokenURI: tokenURI, body: body)
            },
            now: { fixedDate }
        )

        let token = try await provider.getAccessToken(expirationDuration: 3600)
        let cachedToken = try await provider.getAccessToken(expirationDuration: 3600)

        #expect(token == "test-access-token")
        #expect(cachedToken == "test-access-token")
        #expect(await requester.requestCount() == 1)

        let body = try await requester.lastBodyString()
        let fields = try Self.formFields(from: body)
        #expect(fields["grant_type"] == "urn:ietf:params:oauth:grant-type:jwt-bearer")

        guard let assertion = fields["assertion"] else {
            Issue.record("OAuth request body did not include assertion.")
            return
        }
        let segments = assertion.split(separator: ".").map(String.init)
        guard segments.count == 3 else {
            Issue.record("JWT assertion did not have three segments.")
            return
        }

        let header = try Self.decodeSegment(JWTHeader.self, from: segments[0])
        let claims = try Self.decodeSegment(JWTClaims.self, from: segments[1])
        #expect(header.alg == "RS256")
        #expect(header.typ == "JWT")
        #expect(header.kid == credentials.privateKeyId)
        #expect(claims.iss == credentials.clientEmail)
        #expect(claims.scope == FirestoreAccessScope.datastore.value)
        #expect(claims.aud == credentials.tokenURI.absoluteString)
        #expect(claims.iat == Int(fixedDate.timeIntervalSince1970))
        #expect(claims.exp == Int(fixedDate.timeIntervalSince1970) + 3600)

        let signingInput = "\(segments[0]).\(segments[1])"
        let signatureData = try Self.base64URLDecode(segments[2])
        let signature = _RSA.Signing.RSASignature(rawRepresentation: signatureData)
        #expect(
            privateKey.publicKey.isValidSignature(
                signature,
                for: Data(signingInput.utf8),
                padding: .insecurePKCS1v1_5
            )
        )
    }

    @Test("Service account provider shares concurrent token requests")
    func testServiceAccountProviderSharesConcurrentTokenRequests() async throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let credentials = try Self.makeCredentials(privateKey: privateKey)
        let requester = DelayedOAuthTokenRequester()
        let provider = try ServiceAccountAccessTokenProvider(
            credentials: credentials,
            scope: FirestoreAccessScope.datastore,
            tokenRequester: { tokenURI, body in
                try await requester.request(tokenURI: tokenURI, body: body)
            },
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        async let firstToken = provider.getAccessToken(expirationDuration: 3600)
        async let secondToken = provider.getAccessToken(expirationDuration: 3600)
        let tokens = try await (firstToken, secondToken)

        #expect(tokens.0 == "delayed-access-token")
        #expect(tokens.1 == "delayed-access-token")
        #expect(await requester.requestCount() == 1)
    }

    @Test("Metadata server provider requests token with metadata header and caches token")
    func testMetadataServerProviderRequestsTokenWithMetadataHeaderAndCachesToken() async throws {
        let requester = RecordingMetadataTokenRequester()
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let provider = MetadataServerAccessTokenProvider(
            scope: FirestoreAccessScope.cloudPlatform,
            metadataBaseURL: metadataBaseURL,
            tokenRequester: { request in
                try await requester.request(request)
            },
            now: { fixedDate }
        )

        let token = try await provider.getAccessToken(expirationDuration: 3600)
        let cachedToken = try await provider.getAccessToken(expirationDuration: 3600)
        let request = try await requester.lastRequest()

        #expect(token == "metadata-access-token")
        #expect(cachedToken == "metadata-access-token")
        #expect(await requester.requestCount() == 1)
        #expect(provider.scope.value == FirestoreAccessScope.cloudPlatform.value)
        #expect(request.value(forHTTPHeaderField: "Metadata-Flavor") == "Google")
        #expect(request.url?.path == "/computeMetadata/v1/instance/service-accounts/default/token")
        #expect(request.url?.query == nil)
    }

    @Test("Application Default Credentials load service account JSON")
    func testApplicationDefaultCredentialsLoadServiceAccountJSON() throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let credentials = try Self.makeCredentials(privateKey: privateKey)
        let directory = try Self.makeTemporaryDirectory()
        defer {
            Self.removeTemporaryDirectory(directory)
        }

        let credentialURL = try Self.writeCredentials(credentials, to: directory)

        let environment = ["GOOGLE_APPLICATION_CREDENTIALS": credentialURL.path]
        let loaded = try GoogleApplicationDefaultCredentials.serviceAccountCredentials(environment: environment)
        let provider = try GoogleApplicationDefaultCredentials.accessTokenProvider(environment: environment)

        #expect(loaded == credentials)
        #expect(provider.scope.value == FirestoreAccessScope.datastore.value)
    }

    @Test("Application Default Credentials load well-known service account JSON")
    func testApplicationDefaultCredentialsLoadWellKnownServiceAccountJSON() throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let credentials = try Self.makeCredentials(privateKey: privateKey, projectId: "well-known-project")
        let directory = try Self.makeTemporaryDirectory()
        defer {
            Self.removeTemporaryDirectory(directory)
        }

        let credentialURL = try Self.writeCredentials(
            credentials,
            to: directory,
            fileName: "application_default_credentials.json"
        )

        let loaded = try GoogleApplicationDefaultCredentials.serviceAccountCredentials(
            environment: [:],
            wellKnownCredentialsURL: credentialURL
        )
        let projectID = try GoogleApplicationDefaultCredentials.projectID(
            environment: [:],
            wellKnownCredentialsURL: credentialURL
        )

        #expect(loaded == credentials)
        #expect(projectID == "well-known-project")
    }

    @Test("Application Default Credentials prefer environment credentials over well-known file")
    func testApplicationDefaultCredentialsPreferEnvironmentCredentialsOverWellKnownFile() throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let environmentCredentials = try Self.makeCredentials(
            privateKey: privateKey,
            projectId: "environment-project"
        )
        let wellKnownCredentials = try Self.makeCredentials(
            privateKey: privateKey,
            projectId: "well-known-project"
        )
        let directory = try Self.makeTemporaryDirectory()
        defer {
            Self.removeTemporaryDirectory(directory)
        }

        let environmentCredentialURL = try Self.writeCredentials(
            environmentCredentials,
            to: directory,
            fileName: "environment-service-account.json"
        )
        let wellKnownCredentialURL = try Self.writeCredentials(
            wellKnownCredentials,
            to: directory,
            fileName: "application_default_credentials.json"
        )

        let environment = ["GOOGLE_APPLICATION_CREDENTIALS": environmentCredentialURL.path]
        let loaded = try GoogleApplicationDefaultCredentials.serviceAccountCredentials(
            environment: environment,
            wellKnownCredentialsURL: wellKnownCredentialURL
        )
        let projectID = try GoogleApplicationDefaultCredentials.projectID(
            environment: environment,
            wellKnownCredentialsURL: wellKnownCredentialURL
        )

        #expect(loaded == environmentCredentials)
        #expect(projectID == "environment-project")
    }

    @Test("Application Default Credentials resolve project ID from well-known service account JSON")
    func testApplicationDefaultCredentialsResolveProjectIDFromWellKnownServiceAccountJSON() async throws {
        let privateKey = try _RSA.Signing.PrivateKey(keySize: .bits2048)
        let credentials = try Self.makeCredentials(privateKey: privateKey, projectId: "well-known-project")
        let directory = try Self.makeTemporaryDirectory()
        defer {
            Self.removeTemporaryDirectory(directory)
        }

        let credentialURL = try Self.writeCredentials(
            credentials,
            to: directory,
            fileName: "application_default_credentials.json"
        )
        let requester = RecordingMetadataProjectIDRequester()
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))

        let projectID = try await GoogleApplicationDefaultCredentials.resolvedProjectID(
            environment: [:],
            wellKnownCredentialsURL: credentialURL,
            metadataBaseURL: metadataBaseURL,
            metadataProjectIDRequester: { request in
                try await requester.request(request)
            }
        )

        #expect(projectID == "well-known-project")
        #expect(await requester.requestCount() == 0)
    }

    @Test("Application Default Credentials reject unsupported well-known credential type")
    func testApplicationDefaultCredentialsRejectUnsupportedWellKnownCredentialType() throws {
        let directory = try Self.makeTemporaryDirectory()
        defer {
            Self.removeTemporaryDirectory(directory)
        }

        let credentialURL = directory.appendingPathComponent("application_default_credentials.json")
        let unsupportedCredentials = Data(
            """
            {
              "type": "authorized_user",
              "client_id": "test-client-id",
              "client_secret": "test-client-secret",
              "refresh_token": "test-refresh-token"
            }
            """.utf8
        )
        try unsupportedCredentials.write(to: credentialURL)
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))

        var didThrowUnsupportedCredential = false
        do {
            _ = try GoogleApplicationDefaultCredentials.accessTokenProvider(
                environment: [:],
                wellKnownCredentialsURL: credentialURL,
                metadataBaseURL: metadataBaseURL,
                metadataTokenRequester: { _ in
                    MetadataServerAccessTokenProvider.MetadataTokenResponse(
                        accessToken: "metadata-access-token",
                        expiresIn: 3600,
                        tokenType: "Bearer"
                    )
                }
            )
        } catch FirestoreError.invalidConfiguration(let message) {
            didThrowUnsupportedCredential = message.contains("not a service account")
        } catch {
            didThrowUnsupportedCredential = false
        }

        #expect(didThrowUnsupportedCredential)
    }

    @Test("Application Default Credentials fall back to metadata server provider")
    func testApplicationDefaultCredentialsFallBackToMetadataServerProvider() async throws {
        let requester = RecordingMetadataTokenRequester()
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))
        let provider = try GoogleApplicationDefaultCredentials.accessTokenProvider(
            scope: FirestoreAccessScope.cloudPlatform,
            environment: [:],
            wellKnownCredentialsURL: nil,
            metadataBaseURL: metadataBaseURL,
            metadataTokenRequester: { request in
                try await requester.request(request)
            }
        )

        let token = try await provider.getAccessToken(expirationDuration: 3600)

        #expect(token == "metadata-access-token")
        #expect(provider.scope.value == FirestoreAccessScope.cloudPlatform.value)
        #expect(await requester.requestCount() == 1)
    }

    @Test("Metadata server project ID provider requests project ID with metadata header")
    func testMetadataServerProjectIDProviderRequestsProjectIDWithMetadataHeader() async throws {
        let requester = RecordingMetadataProjectIDRequester()
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))
        let provider = MetadataServerProjectIDProvider(
            metadataBaseURL: metadataBaseURL,
            projectIDRequester: { request in
                try await requester.request(request)
            }
        )

        let projectID = try await provider.projectID()
        let request = try await requester.lastRequest()

        #expect(projectID == "metadata-project")
        #expect(await requester.requestCount() == 1)
        #expect(request.value(forHTTPHeaderField: "Metadata-Flavor") == "Google")
        #expect(request.url?.path == "/computeMetadata/v1/project/project-id")
        #expect(request.url?.query == nil)
    }

    @Test("Application Default Credentials resolve project ID from metadata server")
    func testApplicationDefaultCredentialsResolveProjectIDFromMetadataServer() async throws {
        let requester = RecordingMetadataProjectIDRequester()
        let metadataBaseURL = try #require(URL(string: "http://metadata.test/computeMetadata/v1"))

        let projectID = try await GoogleApplicationDefaultCredentials.resolvedProjectID(
            environment: [:],
            wellKnownCredentialsURL: nil,
            metadataBaseURL: metadataBaseURL,
            metadataProjectIDRequester: { request in
                try await requester.request(request)
            }
        )

        #expect(projectID == "metadata-project")
        #expect(await requester.requestCount() == 1)
    }

    @Test("Application Default Credentials read project ID from environment")
    func testApplicationDefaultCredentialsReadProjectIDFromEnvironment() throws {
        let projectID = try GoogleApplicationDefaultCredentials.projectID(
            environment: ["GOOGLE_CLOUD_PROJECT": "metadata-project"]
        )

        #expect(projectID == "metadata-project")
    }

    @Test("Application Default Credentials throw when environment is missing")
    func testApplicationDefaultCredentialsThrowWhenEnvironmentIsMissing() {
        var didThrowInvalidConfiguration = false
        do {
            _ = try GoogleApplicationDefaultCredentials.serviceAccountCredentials(
                environment: [:],
                wellKnownCredentialsURL: nil
            )
        } catch FirestoreError.invalidConfiguration(_) {
            didThrowInvalidConfiguration = true
        } catch {
            didThrowInvalidConfiguration = false
        }

        #expect(didThrowInvalidConfiguration)
    }

    private static func makeCredentials(
        privateKey: _RSA.Signing.PrivateKey,
        projectId: String = "test-project"
    ) throws -> ServiceAccountCredentials {
        try ServiceAccountCredentials(
            projectId: projectId,
            privateKeyId: "test-key-id",
            privateKey: privateKey.pkcs8PEMRepresentation,
            clientEmail: "firebase-api@\(projectId).iam.gserviceaccount.com",
            clientId: "1234567890"
        )
    }

    private static func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func removeTemporaryDirectory(_ directory: URL) {
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            Issue.record("Failed to remove temporary credential directory: \(error)")
        }
    }

    private static func writeCredentials(
        _ credentials: ServiceAccountCredentials,
        to directory: URL,
        fileName: String = "service-account.json"
    ) throws -> URL {
        let credentialURL = directory.appendingPathComponent(fileName)
        let credentialData = try JSONEncoder().encode(credentials)
        try credentialData.write(to: credentialURL)
        return credentialURL
    }

    private static func formFields(from body: String) throws -> [String: String] {
        guard let components = URLComponents(string: "?\(body)") else {
            throw FirestoreError.invalidConfiguration("OAuth request body is not valid form data.")
        }

        var fields: [String: String] = [:]
        for queryItem in components.queryItems ?? [] {
            fields[queryItem.name] = queryItem.value ?? ""
        }
        return fields
    }

    private static func decodeSegment<T: Decodable>(_ type: T.Type, from segment: String) throws -> T {
        let data = try base64URLDecode(segment)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func base64URLDecode(_ value: String) throws -> Data {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = (4 - base64.count % 4) % 4
        base64.append(String(repeating: "=", count: padding))

        guard let data = Data(base64Encoded: base64) else {
            throw FirestoreError.invalidConfiguration("Invalid base64url value.")
        }
        return data
    }

    private struct JWTHeader: Decodable {
        let alg: String
        let typ: String
        let kid: String
    }

    private struct JWTClaims: Decodable {
        let iss: String
        let scope: String
        let aud: String
        let iat: Int
        let exp: Int
    }
}

private actor RecordingOAuthTokenRequester {
    private var requests: [(tokenURI: URL, body: Data)] = []

    func request(
        tokenURI: URL,
        body: Data
    ) async throws -> ServiceAccountAccessTokenProvider.OAuthTokenResponse {
        requests.append((tokenURI: tokenURI, body: body))
        return ServiceAccountAccessTokenProvider.OAuthTokenResponse(
            accessToken: "test-access-token",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
    }

    func requestCount() -> Int {
        requests.count
    }

    func lastBodyString() throws -> String {
        guard let body = requests.last?.body else {
            throw FirestoreError.invalidConfiguration("No OAuth token request was recorded.")
        }
        guard let bodyString = String(data: body, encoding: .utf8) else {
            throw FirestoreError.invalidConfiguration("OAuth token request body is not UTF-8.")
        }
        return bodyString
    }
}

private actor DelayedOAuthTokenRequester {
    private var requests: [(tokenURI: URL, body: Data)] = []

    func request(
        tokenURI: URL,
        body: Data
    ) async throws -> ServiceAccountAccessTokenProvider.OAuthTokenResponse {
        requests.append((tokenURI: tokenURI, body: body))
        try await Task.sleep(for: .milliseconds(50))
        return ServiceAccountAccessTokenProvider.OAuthTokenResponse(
            accessToken: "delayed-access-token",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
    }

    func requestCount() -> Int {
        requests.count
    }
}

private actor RecordingMetadataTokenRequester {
    private var requests: [URLRequest] = []

    func request(_ request: URLRequest) async throws -> MetadataServerAccessTokenProvider.MetadataTokenResponse {
        requests.append(request)
        return MetadataServerAccessTokenProvider.MetadataTokenResponse(
            accessToken: "metadata-access-token",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
    }

    func requestCount() -> Int {
        requests.count
    }

    func lastRequest() throws -> URLRequest {
        guard let request = requests.last else {
            throw FirestoreError.invalidConfiguration("No metadata token request was recorded.")
        }
        return request
    }
}

private actor RecordingMetadataProjectIDRequester {
    private var requests: [URLRequest] = []

    func request(_ request: URLRequest) async throws -> String {
        requests.append(request)
        return "metadata-project\n"
    }

    func requestCount() -> Int {
        requests.count
    }

    func lastRequest() throws -> URLRequest {
        guard let request = requests.last else {
            throw FirestoreError.invalidConfiguration("No metadata project ID request was recorded.")
        }
        return request
    }
}
