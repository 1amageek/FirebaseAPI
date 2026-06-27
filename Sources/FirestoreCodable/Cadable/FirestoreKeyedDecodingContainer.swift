import Foundation
import FirestoreCore

struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

    var codingPath: [CodingKey] { manager.codingPath }

    var decoder: _FirestoreDecoder

    var allKeys: [Key] { data.keys.compactMap { Key(stringValue: $0) } }

    var data: [String: Any]

    var manager: CodingKeyManager

    init(decoder: _FirestoreDecoder, data: [String : Any], manager: CodingKeyManager) {
        self.decoder = decoder
        self.data = data
        self.manager = manager
    }

    func contains(_ key: Key) -> Bool {
        return data[key.stringValue] != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        return data[key.stringValue] is NSNull
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Bool else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Bool"))
        }
        return value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? String else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a String"))
        }
        return value
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeDouble(
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeFloat(
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        return try firestoreDecodeInteger(
            type,
            from: data[key.stringValue] ?? "null",
            codingPath: codingPath,
            manager: manager
        )
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        if contains(key), let value = data[key.stringValue] {
            if let specialValue = try firestoreDecodeSpecialValue(
                type,
                from: value,
                decoder: decoder,
                codingPath: codingPath,
                manager: manager
            ) {
                return specialValue
            }

            let decoder = _FirestoreDecoder(
                type,
                from: value,
                passthroughTypes: decoder.passthroughTypes,
                manager: manager
            )
            return try T(from: decoder)
        } else {
            if let missingValue = firestoreDecodeMissingValue(type) {
                return missingValue
            }

            guard let userInfoKey = FirestoreDecoder.documentRefUserInfoKey,
                  let reference = decoder.userInfo[userInfoKey] as? DocumentReference else {
                throw firestoreValueNotFound(type, codingPath: codingPath, manager: manager)
            }

            if let generatedValue = try firestoreDecodeGeneratedReferenceField(
                type,
                reference: reference,
                codingPath: codingPath,
                manager: manager
            ) {
                return generatedValue
            }

            throw firestoreValueNotFound(type, codingPath: codingPath, manager: manager)
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? [String: Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected keyed container"))
        }
        let nestedDecoder = _FirestoreDecoder(type, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return try nestedDecoder.container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue))
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? [Any] else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected unkeyed container"))
        }
        let nestedDecoder = _FirestoreDecoder([Any].self, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return try nestedDecoder.unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        decoder
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        decoder
    }
}
