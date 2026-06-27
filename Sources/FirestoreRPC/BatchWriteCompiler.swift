import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct BatchWriteCompiler {
    package let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeBatchWriteRequest(
        writes: [WriteData],
        labels: [String: String] = [:]
    ) throws -> Google_Firestore_V1_BatchWriteRequest {
        try validateNoDuplicateDocuments(writes)
        let compiledWrites = try WriteCompiler(database: database).makeWrites(writes)
        return Google_Firestore_V1_BatchWriteRequest.with {
            $0.database = database.database
            $0.writes = compiledWrites
            $0.labels = labels
        }
    }

    private func validateNoDuplicateDocuments(_ writes: [WriteData]) throws {
        var seen: Set<String> = []
        for write in writes {
            let name = write.documentReference.name
            guard seen.insert(name).inserted else {
                throw FirestoreError.invalidOperation("BatchWrite requests cannot write to the same document more than once.")
            }
        }
    }
}
