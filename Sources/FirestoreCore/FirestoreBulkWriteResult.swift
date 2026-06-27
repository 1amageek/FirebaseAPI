import Foundation

public struct FirestoreBulkWriteResult: Equatable, Sendable {
    public let results: [FirestoreBulkWriteOperationResult]

    public var succeeded: [FirestoreBulkWriteOperationResult] {
        results.filter(\.succeeded)
    }

    public var failed: [FirestoreBulkWriteOperationResult] {
        results.filter { !$0.succeeded }
    }

    public var hasFailures: Bool {
        !failed.isEmpty
    }

    public init(results: [FirestoreBulkWriteOperationResult]) {
        self.results = results
    }
}
