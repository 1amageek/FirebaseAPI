import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package struct PartitionQueryCompiler {
    package let collectionGroup: CollectionGroup

    package init(collectionGroup: CollectionGroup) {
        self.collectionGroup = collectionGroup
    }

    package func makePartitionQueryRequest(
        partitionPointCount: Int,
        pageSize: Int = 0,
        pageToken: String = "",
        readTime: Timestamp? = nil
    ) throws -> Google_Firestore_V1_PartitionQueryRequest {
        guard partitionPointCount > 0 else {
            throw FirestoreError.invalidQuery("PartitionQuery partitionPointCount must be greater than zero.")
        }
        guard pageSize >= 0 else {
            throw FirestoreError.invalidQuery("PartitionQuery pageSize must be greater than or equal to zero.")
        }
        guard pageSize <= Int(Int32.max) else {
            throw FirestoreError.invalidQuery("PartitionQuery pageSize exceeds Int32 range.")
        }

        let query = collectionGroup.makeQuery(predicates: [.orderBy("__name__", false)])
        let structuredQuery = try QueryCompiler(query: query).makeStructuredQuery()

        return Google_Firestore_V1_PartitionQueryRequest.with {
            $0.parent = collectionGroup.database.path
            $0.structuredQuery = structuredQuery
            $0.partitionCount = Int64(partitionPointCount)
            $0.pageSize = Int32(pageSize)
            $0.pageToken = pageToken
            if let readTime {
                $0.readTime = Google_Protobuf_Timestamp.with {
                    $0.seconds = readTime.seconds
                    $0.nanos = readTime.nanos
                }
            }
        }
    }
}
