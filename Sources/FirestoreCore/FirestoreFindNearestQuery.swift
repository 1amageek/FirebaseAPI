import Foundation

public struct FirestoreFindNearestQuery: Sendable, Equatable {
    public let vectorField: String
    public let queryVector: FirestoreVector
    public let limit: Int
    public let distanceMeasure: FirestoreVectorDistanceMeasure
    public let distanceResultField: String?
    public let distanceThreshold: Double?

    public init(
        vectorField: String,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String? = nil,
        distanceThreshold: Double? = nil
    ) {
        self.vectorField = vectorField
        self.queryVector = queryVector
        self.limit = limit
        self.distanceMeasure = distanceMeasure
        self.distanceResultField = distanceResultField
        self.distanceThreshold = distanceThreshold
    }
}
