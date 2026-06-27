import Foundation

struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {

    var codingPath: [CodingKey] { manager.codingPath }

    var decoder: _FirestoreDecoder

    var count: Int? { data.count }

    var isAtEnd: Bool { currentIndex >= data.count }

    var currentIndex: Int = 0

    var data: [Any]

    var manager: CodingKeyManager

    private var currentValueForMessage: Any {
        isAtEnd ? "end of unkeyed container" : data[currentIndex]
    }

    init(decoder: _FirestoreDecoder, data: [Any], manager: CodingKeyManager) {
        self.decoder = decoder
        self.data = data
        self.manager = manager
    }

    private func currentValue(expected type: Any.Type) throws -> Any {
        guard !isAtEnd else {
            throw firestoreValueNotFound(type, codingPath: codingPath, manager: manager)
        }
        return data[currentIndex]
    }

    mutating func decodeNil() throws -> Bool {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        let value = try currentValue(expected: Any?.self)
        guard value is NSNull else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(currentValueForMessage): Expected NSNull"))
        }
        currentIndex += 1
        return true
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        let rawValue = try currentValue(expected: type)
        guard let value = rawValue as? Bool else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(currentValueForMessage): Expected a Bool"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: String.Type) throws -> String {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        let rawValue = try currentValue(expected: type)
        guard let value = rawValue as? String else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(currentValueForMessage): Expected a String"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Double"))
        }
        let value = try firestoreDecodeDouble(from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Float"))
        }
        let value = try firestoreDecodeFloat(from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Int"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Int8"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Int16"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Int32"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a Int64"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a UInt"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a UInt8"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a UInt16"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a UInt32"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected a UInt64"))
        }
        let value = try firestoreDecodeInteger(type, from: data[currentIndex], codingPath: codingPath, manager: manager)
        currentIndex += 1
        return value
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        let value = try currentValue(expected: type)
        if let specialValue = try firestoreDecodeSpecialValue(
            type,
            from: value,
            decoder: decoder,
            codingPath: codingPath,
            manager: manager
        ) {
            currentIndex += 1
            return specialValue
        } else {
            let decoder = _FirestoreDecoder(type, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
            let decodedValue = try T(from: decoder)
            currentIndex += 1
            return decodedValue
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        guard !isAtEnd, let value = data[currentIndex] as? [String: Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected unkeyed container"))
        }
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        currentIndex += 1
        let nestedDecoder = _FirestoreDecoder(type, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return KeyedDecodingContainer(try nestedDecoder.container(keyedBy: type))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !isAtEnd, let value = data[currentIndex] as? [Any] else {
            throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected unkeyed container"))
        }
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        currentIndex += 1
        let nestedDecoder = _FirestoreDecoder([Any].self, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return try nestedDecoder.unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        decoder
    }
}
