import Foundation
import FirestoreCore
import FirestoreProtobuf

package struct ListenRequestBuilder {
    private let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeAddTargetRequest(_ target: Google_Firestore_V1_Target) -> Google_Firestore_V1_ListenRequest {
        Google_Firestore_V1_ListenRequest.with {
            $0.database = database.database
            $0.addTarget = target
        }
    }

    package func makeRemoveTargetRequest(targetID: Int32) -> Google_Firestore_V1_ListenRequest {
        Google_Firestore_V1_ListenRequest.with {
            $0.database = database.database
            $0.removeTarget = targetID
        }
    }
}
