import Foundation

public indirect enum FirestoreExplainValue: Sendable, Equatable {
    case null
    case number(Double)
    case string(String)
    case bool(Bool)
    case list([FirestoreExplainValue])
    case map([String: FirestoreExplainValue])

    public var anyValue: Any {
        switch self {
        case .null:
            return NSNull()
        case .number(let value):
            return value
        case .string(let value):
            return value
        case .bool(let value):
            return value
        case .list(let values):
            return values.map(\.anyValue)
        case .map(let values):
            return values.mapValues(\.anyValue)
        }
    }
}
