import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct ListenTargetBuilder {
    package init() {}

    package func makeDocumentTarget(
        for reference: DocumentReference,
        targetID: Int32
    ) -> Google_Firestore_V1_Target {
        return Google_Firestore_V1_Target.with {
            $0.documents = Google_Firestore_V1_Target.DocumentsTarget.with {
                $0.documents = [reference.name]
            }
            $0.targetID = targetID
        }
    }

    package func makeQueryTarget(
        for query: Query,
        targetID: Int32
    ) throws -> Google_Firestore_V1_Target {
        let structuredQuery = try QueryCompiler(query: query).makeStructuredQuery()
        return Google_Firestore_V1_Target.with {
            $0.query = Google_Firestore_V1_Target.QueryTarget.with {
                $0.parent = query.name
                $0.structuredQuery = structuredQuery
            }
            $0.targetID = targetID
        }
    }
}
