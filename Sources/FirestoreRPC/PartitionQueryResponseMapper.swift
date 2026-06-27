import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct PartitionQueryResponseMapper {
    private let database: Database
    private let runtime: (any FirestoreQueryRuntime)?

    package init(database: Database, runtime: (any FirestoreQueryRuntime)? = nil) {
        self.database = database
        self.runtime = runtime
    }

    package func makePartitionReferences(
        from responses: [Google_Firestore_V1_PartitionQueryResponse]
    ) throws -> [DocumentReference] {
        try responses.flatMap { response in
            try response.partitions.map(makePartitionReference)
        }
    }

    package func makePartitionedQueries(
        for collectionGroup: CollectionGroup,
        partitionReferences: [DocumentReference]
    ) throws -> [Query] {
        let baseQuery = try collectionGroup.order(by: FieldPath.documentID())
        guard !partitionReferences.isEmpty else {
            return [baseQuery]
        }

        return partitionReferences.indices.map { index in
            var query = baseQuery
            if index > partitionReferences.startIndex {
                query = query.start(at: [partitionReferences[index - 1]])
            }
            query = query.end(before: [partitionReferences[index]])
            return query
        } + [
            baseQuery.start(at: [partitionReferences[partitionReferences.index(before: partitionReferences.endIndex)]])
        ]
    }

    private func makePartitionReference(
        from cursor: Google_Firestore_V1_Cursor
    ) throws -> DocumentReference {
        guard cursor.values.count == 1,
              case .referenceValue(let name)? = cursor.values.first?.valueType
        else {
            throw FirestoreError.invalidQuery("PartitionQuery cursors must contain exactly one document reference value.")
        }

        let reference = try DocumentReference(
            name: name,
            runtime: runtime as? any FirestoreReferenceRuntime
        )
        guard reference.database == database else {
            throw FirestoreError.databaseMismatch(
                expected: database.database,
                actual: reference.database.database
            )
        }
        return reference
    }
}
