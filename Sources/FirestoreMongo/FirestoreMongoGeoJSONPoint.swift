import FirestoreCore
import Foundation

public struct FirestoreMongoGeoJSONPoint: Equatable, Sendable {
    public let longitude: Double
    public let latitude: Double

    public init(longitude: Double, latitude: Double) throws {
        guard longitude.isFinite, (-180.0...180.0).contains(longitude) else {
            throw FirestoreError.invalidFieldValue("GeoJSON longitude must be finite and between -180 and 180.")
        }
        guard latitude.isFinite, (-90.0...90.0).contains(latitude) else {
            throw FirestoreError.invalidFieldValue("GeoJSON latitude must be finite and between -90 and 90.")
        }

        self.longitude = longitude
        self.latitude = latitude
    }

    public init(_ geoPoint: GeoPoint) throws {
        try self.init(longitude: geoPoint.longitude, latitude: geoPoint.latitude)
    }

    public var document: FirestoreMongoDocument {
        [
            "type": .string("Point"),
            "coordinates": .array([
                .double(longitude),
                .double(latitude)
            ])
        ]
    }

    public var value: FirestoreMongoValue {
        .document(document)
    }
}
