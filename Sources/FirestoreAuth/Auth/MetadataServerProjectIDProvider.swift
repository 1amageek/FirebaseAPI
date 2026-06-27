import Foundation
import FirestoreCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct MetadataServerProjectIDProvider: Sendable {
    private let metadataBaseURL: URL
    private let projectIDRequester: MetadataProjectIDRequester

    public init() throws {
        guard let metadataBaseURL = URL(string: "http://metadata.google.internal/computeMetadata/v1") else {
            throw FirestoreError.invalidConfiguration("Default metadata server endpoint is not a valid URL.")
        }
        self.init(
            metadataBaseURL: metadataBaseURL,
            projectIDRequester: Self.defaultProjectIDRequester
        )
    }

    init(
        metadataBaseURL: URL,
        projectIDRequester: @escaping MetadataProjectIDRequester
    ) {
        self.metadataBaseURL = metadataBaseURL
        self.projectIDRequester = projectIDRequester
    }

    public func projectID() async throws -> String {
        let request = try makeProjectIDRequest()
        let projectID = try await projectIDRequester(request)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectID.isEmpty else {
            throw FirestoreError.invalidConfiguration("Metadata server project ID response was empty.")
        }
        return projectID
    }

    private func makeProjectIDRequest() throws -> URLRequest {
        let projectIDURL = try metadataURL(path: "project/project-id")
        var request = URLRequest(url: projectIDURL)
        request.httpMethod = "GET"
        request.addValue("Google", forHTTPHeaderField: "Metadata-Flavor")
        return request
    }

    private func metadataURL(path: String) throws -> URL {
        let url = metadataBaseURL.appendingPathComponent(path)
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let url = components.url else {
            throw FirestoreError.invalidConfiguration("Metadata server endpoint is not a valid URL.")
        }
        return url
    }

    private static func defaultProjectIDRequester(_ request: URLRequest) async throws -> String {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FirestoreError.invalidConfiguration("Metadata server returned a non-HTTP response.")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw FirestoreError.invalidConfiguration(
                "Metadata server project ID request failed with HTTP \(httpResponse.statusCode). \(responseBody)"
            )
        }
        guard let projectID = String(data: data, encoding: .utf8) else {
            throw FirestoreError.invalidConfiguration("Metadata server project ID response was not UTF-8.")
        }
        return projectID
    }

    static var defaultProjectIDRequesterForADC: MetadataProjectIDRequester {
        Self.defaultProjectIDRequester
    }

    typealias MetadataProjectIDRequester = @Sendable (URLRequest) async throws -> String
}
