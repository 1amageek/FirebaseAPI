import Foundation

public enum AggregateValue: Sendable, Equatable {
    case integer(Int64)
    case double(Double)
    case null

    public var int64Value: Int64? {
        if case .integer(let value) = self {
            return value
        }
        return nil
    }

    public var intValue: Int? {
        guard let value = int64Value else {
            return nil
        }
        return Int(exactly: value)
    }

    public var doubleValue: Double? {
        switch self {
        case .integer(let value):
            return Double(value)
        case .double(let value):
            return value
        case .null:
            return nil
        }
    }
}
