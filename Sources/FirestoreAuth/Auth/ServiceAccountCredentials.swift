import Foundation
import FirestoreCore

public struct ServiceAccountCredentials: Codable, Equatable, Sendable {
    let type: String
    public let projectId: String
    let privateKeyId: String
    let privateKey: String
    public let clientEmail: String
    let clientId: String?
    let tokenURI: URL

    public init(
        type: String = "service_account",
        projectId: String,
        privateKeyId: String,
        privateKey: String,
        clientEmail: String,
        clientId: String? = nil,
        tokenURI: URL? = nil
    ) throws {
        self.type = type
        self.projectId = projectId
        self.privateKeyId = privateKeyId
        self.privateKey = privateKey
        self.clientEmail = clientEmail
        self.clientId = clientId
        if let tokenURI {
            self.tokenURI = tokenURI
        } else {
            guard let defaultTokenURI = URL(string: "https://oauth2.googleapis.com/token") else {
                throw FirestoreError.invalidConfiguration("Default OAuth token endpoint is not a valid URL.")
            }
            self.tokenURI = defaultTokenURI
        }
        try validate()
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        guard type == "service_account" else {
            throw FirestoreError.invalidConfiguration("Credential JSON is not a service account.")
        }

        projectId = try container.decode(String.self, forKey: .projectId)
        privateKeyId = try container.decode(String.self, forKey: .privateKeyId)
        privateKey = try container.decode(String.self, forKey: .privateKey)
        clientEmail = try container.decode(String.self, forKey: .clientEmail)
        clientId = try container.decodeIfPresent(String.self, forKey: .clientId)

        let tokenURIString = try container.decode(String.self, forKey: .tokenURI)
        guard let tokenURI = URL(string: tokenURIString) else {
            throw FirestoreError.invalidConfiguration("Service account token_uri is not a valid URL.")
        }
        self.tokenURI = tokenURI

        try validate()
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(privateKeyId, forKey: .privateKeyId)
        try container.encode(privateKey, forKey: .privateKey)
        try container.encode(clientEmail, forKey: .clientEmail)
        try container.encodeIfPresent(clientId, forKey: .clientId)
        try container.encode(tokenURI.absoluteString, forKey: .tokenURI)
    }

    public static func load(from url: URL) throws -> ServiceAccountCredentials {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }

    public static func load(from data: Data) throws -> ServiceAccountCredentials {
        try JSONDecoder().decode(ServiceAccountCredentials.self, from: data)
    }

    private func validate() throws {
        guard type == "service_account" else {
            throw FirestoreError.invalidConfiguration("Credential JSON is not a service account.")
        }
        guard !projectId.isEmpty else {
            throw FirestoreError.invalidConfiguration("Service account project_id is empty.")
        }
        guard !privateKeyId.isEmpty else {
            throw FirestoreError.invalidConfiguration("Service account private_key_id is empty.")
        }
        guard !privateKey.isEmpty else {
            throw FirestoreError.invalidConfiguration("Service account private_key is empty.")
        }
        guard !clientEmail.isEmpty else {
            throw FirestoreError.invalidConfiguration("Service account client_email is empty.")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case projectId = "project_id"
        case privateKeyId = "private_key_id"
        case privateKey = "private_key"
        case clientEmail = "client_email"
        case clientId = "client_id"
        case tokenURI = "token_uri"
    }
}
