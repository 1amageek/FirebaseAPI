public struct FirestoreEmbeddedGeoPoint: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) throws(FirestoreEmbeddedError) {
        guard latitude.isFinite, latitude >= -90, latitude <= 90 else {
            throw FirestoreEmbeddedError.invalidValue("Latitude must be finite and between -90 and 90.")
        }
        guard longitude.isFinite, longitude >= -180, longitude <= 180 else {
            throw FirestoreEmbeddedError.invalidValue("Longitude must be finite and between -180 and 180.")
        }
        self.latitude = latitude
        self.longitude = longitude
    }
}
