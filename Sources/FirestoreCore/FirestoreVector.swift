import Foundation

public struct FirestoreVector: Sendable, Equatable, Codable {
    public let values: [Double]

    public var dimensions: Int {
        values.count
    }

    public init(_ values: [Double]) {
        self.values = values
    }

    /// Returns a vector embedding value.
    public static func vector(_ values: [Double]) -> FirestoreVector {
        FirestoreVector(values)
    }

    /// Returns a vector embedding value.
    public static func vector(_ values: [Float]) -> FirestoreVector {
        FirestoreVector(values.map(Double.init))
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var values: [Double] = []
        while !container.isAtEnd {
            values.append(try container.decode(Double.self))
        }
        self.values = values
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for value in values {
            try container.encode(value)
        }
    }
}
