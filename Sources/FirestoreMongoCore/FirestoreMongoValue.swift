public typealias FirestoreMongoDocument = [String: FirestoreMongoValue]

public indirect enum FirestoreMongoValue: Equatable, Sendable {
    case string(String)
    case double(Double)
    case int64(Int64)
    case bool(Bool)
    case array([FirestoreMongoValue])
    case document(FirestoreMongoDocument)
}
