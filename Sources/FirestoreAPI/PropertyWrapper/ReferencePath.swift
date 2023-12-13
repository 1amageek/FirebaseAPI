//
//  ReferencePath.swift
//  ReferencePath
//
//  Created by nori on 2021/09/17.
//

import Foundation

@propertyWrapper
public struct ReferencePath<Value>: Hashable where Value: Hashable {

    var value: Value

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    public static func == (lhs: ReferencePath<Value>, rhs: ReferencePath<Value>) -> Bool {
        return lhs.value == rhs.value
    }
}

public enum ReferencePathDecodingError: Error {
    case decodingIsNotSupported(String)
}

public enum ReferencePathEncodingError: Error {
    case encodingIsNotSupported(String)
}

extension ReferencePath: Codable where Value == String {

    // MARK: - `Codable` implementation.

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            let id = try container.decode(String.self)
            self = ReferencePath(wrappedValue: id)
        } catch {
            throw ReferencePathDecodingError.decodingIsNotSupported("ReferencePath values can only be decoded with Firestore.Decoder")
        }
    }

    public func encode(to encoder: Encoder) throws {
        do {
            var container = encoder.singleValueContainer()
            try container.encode(self.wrappedValue)
        } catch {
            throw ReferencePathEncodingError.encodingIsNotSupported("ReferencePath values can only be encoded with Firestore.Encoder")
        }
    }
}
