public indirect enum FirestoreEmbeddedValue: Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case bytes([UInt8])
    case timestamp(FirestoreEmbeddedTimestamp)
    case geoPoint(FirestoreEmbeddedGeoPoint)
    case reference(FirestoreEmbeddedReference)
    case array([FirestoreEmbeddedValue])
    case map([FirestoreEmbeddedField])
}

public struct FirestoreEmbeddedField: Equatable, Sendable {
    public let name: String
    public let value: FirestoreEmbeddedValue

    public init(_ name: String, _ value: FirestoreEmbeddedValue) throws(FirestoreEmbeddedError) {
        let normalizedName = name.firestoreEmbeddedTrimmedSlashes()
        guard !normalizedName.isEmpty else {
            throw FirestoreEmbeddedError.invalidValue("Field name must not be empty.")
        }
        self.name = normalizedName
        self.value = value
    }
}
