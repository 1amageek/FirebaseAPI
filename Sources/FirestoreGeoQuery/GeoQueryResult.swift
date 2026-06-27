import Foundation
import FirestoreCore

public struct GeoQueryResult: Sendable {
    public let document: QueryDocumentSnapshot
    public let distanceInMeters: Double

    public init(document: QueryDocumentSnapshot, distanceInMeters: Double) {
        self.document = document
        self.distanceInMeters = distanceInMeters
    }
}
