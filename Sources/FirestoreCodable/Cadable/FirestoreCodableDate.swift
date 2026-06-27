import Foundation
import FirestoreCore

extension Date {
    var firestoreTimestamp: Timestamp {
        let seconds = floor(timeIntervalSince1970)
        let nanos = (timeIntervalSince1970 - seconds) * 1_000_000_000
        return Timestamp(seconds: Int64(seconds), nanos: Int32(nanos))
    }
}
