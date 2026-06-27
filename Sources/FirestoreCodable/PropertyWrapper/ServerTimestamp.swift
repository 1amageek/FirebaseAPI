//
//  ServerTimestamp.swift
//

import Foundation
import FirestoreCore

/// Wraps an optional timestamp field so nil values encode to a server timestamp sentinel.
@propertyWrapper
public struct ServerTimestamp<Value> {
    var value: Value?

    public init(wrappedValue value: Value?) {
        self.value = value
    }

    public var wrappedValue: Value? {
        get { value }
        set { value = newValue }
    }
}

extension ServerTimestamp: Equatable where Value: Equatable {}

extension ServerTimestamp: Hashable where Value: Hashable {}

extension ServerTimestamp: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value {
            try container.encode(value)
        } else {
            try container.encode(FieldValue.serverTimestamp())
        }
    }
}

extension ServerTimestamp: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else {
            value = try container.decode(Value.self)
        }
    }
}
