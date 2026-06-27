import Foundation

public struct SnapshotListenOptions: Sendable, Equatable {
    public let includeMetadataChanges: Bool
    public let source: ListenSource

    public init(
        includeMetadataChanges: Bool = false,
        source: ListenSource = .default
    ) {
        self.includeMetadataChanges = includeMetadataChanges
        self.source = source
    }

    public func withIncludeMetadataChanges(_ includeMetadataChanges: Bool) -> SnapshotListenOptions {
        SnapshotListenOptions(
            includeMetadataChanges: includeMetadataChanges,
            source: source
        )
    }

    public func withSource(_ source: ListenSource) -> SnapshotListenOptions {
        SnapshotListenOptions(
            includeMetadataChanges: includeMetadataChanges,
            source: source
        )
    }

    package func validateServerSide() throws {
        guard source != .cache else {
            throw FirestoreError.invalidOperation("Cache-only snapshot listeners are not available in server-side Admin.")
        }
    }
}
