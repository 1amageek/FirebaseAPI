import Foundation

public struct FirestoreVector: Sendable, Equatable, Codable {
    public let values: [Double]

    public var dimensions: Int {
        values.count
    }

    public init(_ values: [Double]) {
        self.values = values
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
