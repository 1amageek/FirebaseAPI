import Foundation
import FirestoreCore

public enum FirestoreGeoHash {
    public static let defaultPrecision = 10

    public static func encode(
        _ point: GeoPoint,
        precision: Int = defaultPrecision
    ) throws -> String {
        try encode(latitude: point.latitude, longitude: point.longitude, precision: precision)
    }

    public static func encode(
        latitude: Double,
        longitude: Double,
        precision: Int = defaultPrecision
    ) throws -> String {
        guard latitude.isFinite,
              longitude.isFinite,
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            throw FirestoreError.invalidFieldValue("GeoHash location must contain a valid latitude and longitude.")
        }
        guard (1...GeoHash.maximumPrecision).contains(precision) else {
            throw FirestoreError.invalidFieldValue("GeoHash precision must be between 1 and \(GeoHash.maximumPrecision).")
        }

        return GeoHash.encode(latitude: latitude, longitude: longitude, precision: precision)
    }
}
