import Foundation
import FirestoreCore
import GRPCCore

extension FirestoreGRPCRuntime {
    internal func authorizedMetadata() async throws -> Metadata {
        switch settings.authenticationMode {
        case .required:
            guard let accessToken = try await getAccessToken(), !accessToken.isEmpty else {
                throw FirestoreError.invalidAccessToken("Access token is empty. Configure an access token provider before performing server requests.")
            }

            var metadata: Metadata = [:]
            metadata.addString("Bearer \(accessToken)", forKey: "authorization")
            return metadata
        case .hostManaged, .disabled:
            try settings.validateAuthenticationBoundary(
                hasAccessTokenProvider: accessTokenProvider != nil,
                allowsHostManagedAuthentication: true
            )
            return [:]
        }
    }
}
