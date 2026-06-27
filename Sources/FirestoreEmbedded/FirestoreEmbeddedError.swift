public enum FirestoreEmbeddedError: Error, Equatable, Sendable {
    case invalidPath(String)
    case invalidValue(String)
}
