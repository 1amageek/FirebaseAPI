import Foundation
import FirestoreCore
import FirestoreProtobuf

package actor ListenRequestStreamController {
    private let requestBuilder: ListenRequestBuilder
    private let target: Google_Firestore_V1_Target
    private var continuation: AsyncStream<Google_Firestore_V1_ListenRequest>.Continuation?
    private var pendingRequests: [Google_Firestore_V1_ListenRequest] = []

    package init(database: Database, target: Google_Firestore_V1_Target) {
        self.requestBuilder = ListenRequestBuilder(database: database)
        self.target = target
    }

    package func makeRequestStream() -> AsyncStream<Google_Firestore_V1_ListenRequest> {
        AsyncStream { streamContinuation in
            Task {
                self.attach(streamContinuation)
            }
        }
    }

    package func openTarget() {
        enqueue(requestBuilder.makeAddTargetRequest(target))
    }

    package func closeTarget() {
        enqueue(requestBuilder.makeRemoveTargetRequest(targetID: target.targetID))
        finish()
    }

    private func attach(_ continuation: AsyncStream<Google_Firestore_V1_ListenRequest>.Continuation) {
        self.continuation = continuation
        for request in pendingRequests {
            continuation.yield(request)
        }
        pendingRequests.removeAll()
    }

    private func enqueue(_ request: Google_Firestore_V1_ListenRequest) {
        guard let continuation else {
            pendingRequests.append(request)
            return
        }
        continuation.yield(request)
    }

    private func finish() {
        continuation?.finish()
        continuation = nil
        pendingRequests.removeAll()
    }
}
