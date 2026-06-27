import Foundation

public enum FirestoreVectorDistanceMeasure: String, CaseIterable, Sendable, Equatable, Codable {
    case euclidean
    case cosine
    case dotProduct = "dot_product"
}
