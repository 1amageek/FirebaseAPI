import Foundation
import FirestoreAuthCore
import FirestoreCore

public enum GoogleApplicationDefaultCredentials {
    public static func serviceAccountCredentials(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> ServiceAccountCredentials {
        try serviceAccountCredentials(
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment)
        )
    }

    static func serviceAccountCredentials(
        environment: [String: String],
        wellKnownCredentialsURL: URL?
    ) throws -> ServiceAccountCredentials {
        guard let credentialURL = credentialURL(
            environment: environment,
            wellKnownCredentialsURL: wellKnownCredentialsURL
        ) else {
            throw FirestoreError.invalidConfiguration(
                "Application Default Credentials service account JSON was not found."
            )
        }

        return try ServiceAccountCredentials.load(from: credentialURL)
    }

    public static func accessTokenProvider(
        scope: any AccessScope = FirestoreAccessScope.datastore,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> any AccessTokenProvider & Sendable {
        try accessTokenProvider(
            scope: scope,
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment),
            metadataBaseURL: defaultMetadataBaseURL(),
            metadataTokenRequester: MetadataServerAccessTokenProvider.defaultTokenRequesterForADC
        )
    }

    static func accessTokenProvider(
        scope: any AccessScope = FirestoreAccessScope.datastore,
        environment: [String: String],
        metadataBaseURL: URL,
        metadataTokenRequester: @escaping MetadataServerAccessTokenProvider.MetadataTokenRequester
    ) throws -> any AccessTokenProvider & Sendable {
        try accessTokenProvider(
            scope: scope,
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment),
            metadataBaseURL: metadataBaseURL,
            metadataTokenRequester: metadataTokenRequester
        )
    }

    static func accessTokenProvider(
        scope: any AccessScope = FirestoreAccessScope.datastore,
        environment: [String: String],
        wellKnownCredentialsURL: URL?,
        metadataBaseURL: URL,
        metadataTokenRequester: @escaping MetadataServerAccessTokenProvider.MetadataTokenRequester
    ) throws -> any AccessTokenProvider & Sendable {
        if let credentialURL = credentialURL(environment: environment, wellKnownCredentialsURL: wellKnownCredentialsURL) {
            let credentials = try ServiceAccountCredentials.load(from: credentialURL)
            return try ServiceAccountAccessTokenProvider(credentials: credentials, scope: scope)
        }

        return MetadataServerAccessTokenProvider(
            scope: scope,
            metadataBaseURL: metadataBaseURL,
            tokenRequester: metadataTokenRequester,
            now: { Date() }
        )
    }

    public static func projectID(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> String? {
        try projectID(
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment)
        )
    }

    static func projectID(
        environment: [String: String],
        wellKnownCredentialsURL: URL?
    ) throws -> String? {
        if let explicitProjectID = environmentProjectID(environment: environment) {
            return explicitProjectID
        }
        if let credentialURL = credentialURL(environment: environment, wellKnownCredentialsURL: wellKnownCredentialsURL) {
            return try ServiceAccountCredentials.load(from: credentialURL).projectId
        }
        return nil
    }

    public static func resolvedProjectID(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) async throws -> String? {
        try await resolvedProjectID(
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment),
            metadataBaseURL: defaultMetadataBaseURL(),
            metadataProjectIDRequester: MetadataServerProjectIDProvider.defaultProjectIDRequesterForADC
        )
    }

    static func resolvedProjectID(
        environment: [String: String],
        metadataBaseURL: URL,
        metadataProjectIDRequester: @escaping MetadataServerProjectIDProvider.MetadataProjectIDRequester
    ) async throws -> String? {
        try await resolvedProjectID(
            environment: environment,
            wellKnownCredentialsURL: defaultWellKnownCredentialsURL(environment: environment),
            metadataBaseURL: metadataBaseURL,
            metadataProjectIDRequester: metadataProjectIDRequester
        )
    }

    static func resolvedProjectID(
        environment: [String: String],
        wellKnownCredentialsURL: URL?,
        metadataBaseURL: URL,
        metadataProjectIDRequester: @escaping MetadataServerProjectIDProvider.MetadataProjectIDRequester
    ) async throws -> String? {
        if let explicitProjectID = environmentProjectID(environment: environment) {
            return explicitProjectID
        }
        if let credentialURL = credentialURL(environment: environment, wellKnownCredentialsURL: wellKnownCredentialsURL) {
            return try ServiceAccountCredentials.load(from: credentialURL).projectId
        }

        return try await MetadataServerProjectIDProvider(
            metadataBaseURL: metadataBaseURL,
            projectIDRequester: metadataProjectIDRequester
        )
        .projectID()
    }

    private static func credentialURL(environment: [String: String], wellKnownCredentialsURL: URL?) -> URL? {
        if let path = credentialPath(environment: environment) {
            return URL(fileURLWithPath: path)
        }
        guard let wellKnownCredentialsURL else {
            return nil
        }
        guard FileManager.default.fileExists(atPath: wellKnownCredentialsURL.path) else {
            return nil
        }
        return wellKnownCredentialsURL
    }

    private static func credentialPath(environment: [String: String]) -> String? {
        guard let path = environment["GOOGLE_APPLICATION_CREDENTIALS"], !path.isEmpty else {
            return nil
        }
        return path
    }

    private static func defaultWellKnownCredentialsURL(environment: [String: String]) -> URL? {
        if let cloudSDKConfig = environment["CLOUDSDK_CONFIG"], !cloudSDKConfig.isEmpty {
            return URL(fileURLWithPath: cloudSDKConfig, isDirectory: true)
                .appendingPathComponent("application_default_credentials.json")
        }

        #if os(Windows)
        if let appData = environment["APPDATA"], !appData.isEmpty {
            return URL(fileURLWithPath: appData, isDirectory: true)
                .appendingPathComponent("gcloud")
                .appendingPathComponent("application_default_credentials.json")
        }
        #else
        if let home = environment["HOME"], !home.isEmpty {
            return URL(fileURLWithPath: home, isDirectory: true)
                .appendingPathComponent(".config")
                .appendingPathComponent("gcloud")
                .appendingPathComponent("application_default_credentials.json")
        }
        #endif

        return nil
    }

    private static func environmentProjectID(environment: [String: String]) -> String? {
        for key in ["GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT", "GCP_PROJECT"] {
            if let value = environment[key], !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func defaultMetadataBaseURL() throws -> URL {
        guard let metadataBaseURL = URL(string: "http://metadata.google.internal/computeMetadata/v1") else {
            throw FirestoreError.invalidConfiguration("Default metadata server endpoint is not a valid URL.")
        }
        return metadataBaseURL
    }
}
