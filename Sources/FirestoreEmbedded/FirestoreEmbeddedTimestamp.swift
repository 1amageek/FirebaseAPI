public struct FirestoreEmbeddedTimestamp: Equatable, Comparable, Sendable {
    public let seconds: Int64
    public let nanoseconds: Int32

    public init(seconds: Int64, nanoseconds: Int32) throws(FirestoreEmbeddedError) {
        guard nanoseconds >= 0, nanoseconds < 1_000_000_000 else {
            throw FirestoreEmbeddedError.invalidValue("Timestamp nanoseconds must be between 0 and 999999999.")
        }
        self.seconds = seconds
        self.nanoseconds = nanoseconds
    }

    public static func < (lhs: FirestoreEmbeddedTimestamp, rhs: FirestoreEmbeddedTimestamp) -> Bool {
        if lhs.seconds != rhs.seconds {
            return lhs.seconds < rhs.seconds
        }
        return lhs.nanoseconds < rhs.nanoseconds
    }
}
