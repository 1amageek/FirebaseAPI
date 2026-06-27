//
//  FirestoreDecoder.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/18.
//

import Foundation
import FirestoreCore

public struct FirestoreDecoder {

    static let documentRefUserInfoKey = CodingUserInfoKey(rawValue: "DocumentRefUserInfoKey")

    var passthroughTypes: [Any.Type]

    public init(passthroughTypes: [Any.Type] = [Timestamp.self, GeoPoint.self, DocumentReference.self, FirestoreVector.self, Data.self]) {
        self.passthroughTypes = passthroughTypes
    }

    public func decode<T: Decodable>(_ type: T.Type, from data: Any, in reference: DocumentReference? = nil) throws -> T {
        let manager = CodingKeyManager()
        let decoder = _FirestoreDecoder(
            type,
            from: data,
            passthroughTypes: passthroughTypes,
            manager: manager,
            in: reference
        )
        if let value = try firestoreDecodeSpecialValue(
            type,
            from: data,
            decoder: decoder,
            codingPath: [],
            manager: manager
        ) {
            return value
        }
        return try T.init(from: decoder)
    }
}

class _FirestoreDecoder: Decoder {

    var codingPath: [CodingKey] { manager.codingPath }

    var userInfo: [CodingUserInfoKey : Any] = [:]

    var passthroughTypes: [Any.Type]

    var data: Any

    let manager: CodingKeyManager

    lazy var dateForamatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter
    }()

    init(_ type: Any.Type, from data: Any, passthroughTypes: [Any.Type] = [], manager: CodingKeyManager, in reference: DocumentReference? = nil) {
        self.data = data
        self.passthroughTypes = passthroughTypes
        self.manager = manager
        if let reference {
            if let userInfoKey = FirestoreDecoder.documentRefUserInfoKey {
                self.userInfo[userInfoKey] = reference
            }
        }
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let data = data as? [String: Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected keyed container"))
        }
        return KeyedDecodingContainer(_KeyedDecodingContainer(decoder: self, data: data, manager: manager))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let data = data as? [Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected unkeyed container"))
        }
        return _UnkeyedDecodingContainer(decoder: self, data: data, manager: manager)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _SingleValueDecodingContainer(decoder: self, data: data, manager: manager)
    }
}
