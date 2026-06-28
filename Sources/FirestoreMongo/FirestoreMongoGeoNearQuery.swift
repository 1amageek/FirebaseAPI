import FirestoreCore
import Foundation

public struct FirestoreMongoGeoNearQuery: Equatable, Sendable {
    public let fieldPath: String
    public let point: FirestoreMongoGeoJSONPoint
    public let maxDistanceMeters: Double?
    public let minDistanceMeters: Double?

    public init(
        fieldPath: String,
        point: FirestoreMongoGeoJSONPoint,
        maxDistanceMeters: Double? = nil,
        minDistanceMeters: Double? = nil
    ) throws {
        try Self.validate(fieldPath: fieldPath)
        try Self.validate(distance: maxDistanceMeters, name: "$maxDistance")
        try Self.validate(distance: minDistanceMeters, name: "$minDistance")

        if let minDistanceMeters, let maxDistanceMeters, minDistanceMeters > maxDistanceMeters {
            throw FirestoreError.invalidQuery("$minDistance must be less than or equal to $maxDistance.")
        }

        self.fieldPath = fieldPath
        self.point = point
        self.maxDistanceMeters = maxDistanceMeters
        self.minDistanceMeters = minDistanceMeters
    }

    public var document: FirestoreMongoDocument {
        var nearOptions: FirestoreMongoDocument = [
            "$geometry": point.value
        ]

        if let maxDistanceMeters {
            nearOptions["$maxDistance"] = .double(maxDistanceMeters)
        }
        if let minDistanceMeters {
            nearOptions["$minDistance"] = .double(minDistanceMeters)
        }

        return [
            fieldPath: .document([
                "$near": .document(nearOptions)
            ])
        ]
    }

    private static func validate(fieldPath: String) throws {
        if fieldPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw FirestoreError.invalidFieldPath("Mongo-compatible geo query field path must not be empty.")
        }
    }

    private static func validate(distance: Double?, name: String) throws {
        guard let distance else {
            return
        }
        guard distance.isFinite, distance >= 0 else {
            throw FirestoreError.invalidQuery("\(name) must be finite and greater than or equal to zero.")
        }
    }
}
