import Foundation

public struct AggregateQuerySnapshot: Sendable {
    public let data: [String: AggregateValue]

    public init(data: [String: AggregateValue]) {
        self.data = data
    }

    public func get(_ field: AggregateField) -> AggregateValue? {
        data[field.alias]
    }

    public func get(_ alias: String) -> AggregateValue? {
        data[alias]
    }

    package func requireInteger(_ field: AggregateField) throws -> Int64 {
        guard case .integer(let value) = data[field.alias] else {
            throw FirestoreError.noResult
        }
        return value
    }

    package func requireNumeric(_ field: AggregateField) throws -> AggregateValue {
        guard let value = data[field.alias] else {
            throw FirestoreError.noResult
        }
        switch value {
        case .integer, .double, .null:
            return value
        }
    }
}
