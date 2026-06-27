//
//  FirestoreEncoder.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/15.
//

import Foundation
import FirestoreCore


public struct FirestoreEncoder {

    private var encoder: _FirestoreEncoder

    public init(passthroughTypes: [Any.Type] = [Timestamp.self, GeoPoint.self, DocumentReference.self, FirestoreVector.self, FieldValue.self, Data.self]) {
        self.encoder = _FirestoreEncoder(codingPath: [], passthroughTypes: passthroughTypes)
    }

    public func encode<T>(_ value: T) throws -> [String: Any] where T : Encodable {
        try value.encode(to: encoder)
        guard let topLevel = encoder.data as? [String: Any] else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode value to dictionary."))
        }
        return topLevel
    }
}

class _FirestoreEncoder: Encoder {

    var codingPath: [CodingKey]

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var data: Any? = NSNull()

    var passthroughTypes: [Any.Type]

    init(codingPath: [CodingKey], passthroughTypes: [Any.Type] = []) {
        self.codingPath = codingPath
        self.passthroughTypes = passthroughTypes
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = FirestoreKeyedEncodingContainer<Key>(codingPath: codingPath, encoder: self)
        self.data = container.data
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _FirestoreUnkeyedEncodingContainer(encoder: self)
        self.data = container.data
        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        let container = _FirestoreSingleValueEncodingContainer(codingPath: codingPath, encoder: self)
        self.data = container.encoder.data
        return container
    }
}
