import Foundation
import FirestoreCore
import Synchronization

package final class ListenTargetIDGenerator: Sendable {
    private let nextTargetID = Mutex<Int32>(1)

    package init() {}

    package func next() -> Int32 {
        nextTargetID.withLock {
            let targetID = $0
            $0 += 1
            return targetID
        }
    }
}
