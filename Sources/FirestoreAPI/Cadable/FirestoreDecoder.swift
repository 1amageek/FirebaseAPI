//
//  FirestoreDecoder.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/18.
//

import Foundation

public struct FirestoreDecoder {

    static let documentRefUserInfoKey = CodingUserInfoKey(rawValue: "DocumentRefUserInfoKey")

    var passthroughTypes: [Any.Type]

    public init(passthroughTypes: [Any.Type] = [Timestamp.self, GeoPoint.self, DocumentReference.self]) {
        self.passthroughTypes = passthroughTypes
    }

    public func decode<T: Decodable>(_ type: T.Type, from data: Any, in reference: DocumentReference? = nil) throws -> T {
        return try T.init(from: _FirestoreDecoder(type, from: data, passthroughTypes: passthroughTypes, manager: CodingKeyManager(), in: reference))
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
            self.userInfo[FirestoreDecoder.documentRefUserInfoKey!] = reference
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
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Bool else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Bool"))
        }
        return value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? String else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a String"))
        }
        return value
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        if let value = data[key.stringValue] as? Double {
            return value
        } else if let value = data[key.stringValue] as? Int {
            return Double(value)
        }
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Double"))
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Float else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Float"))
        }
        return value
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        if let value = data[key.stringValue] as? Int {
            return value
        } else if let value = data[key.stringValue] as? Double {
            return Int(value)
        }
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Int"))
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Int8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Int8"))
        }
        return value
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Int16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Int16"))
        }
        return value
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Int32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Int32"))
        }
        return value
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? Int64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a Int64"))
        }
        return value
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? UInt else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a UInt"))
        }
        return value
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? UInt8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a UInt8"))
        }
        return value
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? UInt16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a UInt16"))
        }
        return value
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? UInt32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a UInt32"))
        }
        return value
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? UInt64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[key.stringValue] ?? "null"): Expected a UInt64"))
        }
        return value
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        if contains(key), let value = data[key.stringValue] {
            if decoder.passthroughTypes.contains(where: { $0 == type }) {
                return value as! T
            } else if type == Date.self, let value = data[key.stringValue] as? String {
                return decoder.dateForamatter.date(from: value) as! T
            } else if type == Date.self, let value = data[key.stringValue] as? Timestamp {
                return Date(timeIntervalSince1970: TimeInterval(value.seconds)) as! T
            } else if type == Decimal.self, let value = data[key.stringValue] as? Int {
                return Decimal(value) as! T
            } else if type == Decimal.self, let value = data[key.stringValue] as? Double {
                return Decimal(value) as! T
            } else {
                let decoder = _FirestoreDecoder(type, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
                return try T(from: decoder)
            }
        } else {
            let reference = decoder.userInfo[
                FirestoreDecoder.documentRefUserInfoKey!
            ] as! DocumentReference
            return DocumentID(wrappedValue: reference.documentID) as! T
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
        defer { manager.codingPath.removeLast() }
        guard let value = data[key.stringValue] as? [String: Any] else {
            throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected keyed container"))
        }
        let nestedDecoder = _FirestoreDecoder(type, from: value, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return try nestedDecoder.container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        manager.codingPath.append(FirestoreKey(stringValue: key.stringValue)!)
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

struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {

    var codingPath: [CodingKey] { manager.codingPath }

    var decoder: _FirestoreDecoder

    var count: Int? { data.count }

    var isAtEnd: Bool { currentIndex >= data.count }

    var currentIndex: Int = 0

    var data: [Any]

    var manager: CodingKeyManager

    init(decoder: _FirestoreDecoder, data: [Any], manager: CodingKeyManager) {
        self.decoder = decoder
        self.data = data
        self.manager = manager
    }

    mutating func decodeNil() throws -> Bool {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, data[currentIndex] is NSNull else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected NSNull"))
        }
        currentIndex += 1
        return true
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Bool else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Bool"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: String.Type) throws -> String {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? String else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a String"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Double else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Double"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Float else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Float"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Int else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Int"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Int8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Int8"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Int16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Int16"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Int32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Int32"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? Int64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a Int64"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? UInt else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a UInt"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? UInt8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a UInt8"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? UInt16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a UInt16"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? UInt32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a UInt32"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd, let value = data[currentIndex] as? UInt64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data[currentIndex]): Expected a UInt64"))
        }
        currentIndex += 1
        return value
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        manager.codingPath.append(FirestoreKey(index: currentIndex))
        defer { manager.codingPath.removeLast() }
        guard !isAtEnd else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected value of type \(type)"))
        }
        if decoder.passthroughTypes.contains(where: { $0 == type }) {
            let value = data[currentIndex]
            currentIndex += 1
            return value as! T
        } else if type == Date.self, let value = data[currentIndex] as? String {
            currentIndex += 1
            return decoder.dateForamatter.date(from: value) as! T
        } else if type == Date.self, let value = data[currentIndex] as? Timestamp {
            currentIndex += 1
            return Date(timeIntervalSince1970: TimeInterval(value.seconds)) as! T
        } else if type == Decimal.self, let value = data[currentIndex] as? Int {
            return Decimal(value) as! T
        } else if type == Decimal.self, let value = data[currentIndex] as? Double {
            return Decimal(value) as! T
        } else {
            let value = data[currentIndex]
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

struct _SingleValueDecodingContainer: SingleValueDecodingContainer {

    var codingPath: [CodingKey] { manager.codingPath }

    var decoder: _FirestoreDecoder

    var data: Any

    var manager: CodingKeyManager

    init(decoder: _FirestoreDecoder, data: Any, manager: CodingKeyManager) {
        self.decoder = decoder
        self.data = data
        self.manager = manager
    }

    func decodeNil() -> Bool { data is NSNull }

    func decode(_ type: Bool.Type) throws -> Bool {
        guard let value = data as? Bool else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Bool"))
        }
        return value
    }

    func decode(_ type: String.Type) throws -> String {
        guard let value = data as? String else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a String"))
        }
        return value
    }

    func decode(_ type: Double.Type) throws -> Double {
        guard let value = data as? Double else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Double"))
        }
        return value
    }

    func decode(_ type: Float.Type) throws -> Float {
        guard let value = data as? Float else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Float"))
        }
        return value
    }

    func decode(_ type: Int.Type) throws -> Int {
        guard let value = data as? Int else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Int"))
        }
        return value
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        guard let value = data as? Int8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Int8"))
        }
        return value
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        guard let value = data as? Int16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Int16"))
        }
        return value
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        guard let value = data as? Int32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Int32"))
        }
        return value
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        guard let value = data as? Int64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a Int64"))
        }
        return value
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        guard let value = data as? UInt else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a UInt"))
        }
        return value
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard let value = data as? UInt8 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a UInt8"))
        }
        return value
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard let value = data as? UInt16 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a UInt16"))
        }
        return value
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard let value = data as? UInt32 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a UInt32"))
        }
        return value
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard let value = data as? UInt64 else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "\(manager.message) = \(data): Expected a UInt64"))
        }
        return value
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if decoder.passthroughTypes.contains(where: { $0 == type }) {
            let value = data
            return value as! T
        } else if type == Date.self, let value = data as? String {
            return decoder.dateForamatter.date(from: value) as! T
        } else if type == Date.self, let value = data as? Timestamp {
            return Date(timeIntervalSince1970: TimeInterval(value.seconds)) as! T
        } else if type == Decimal.self, let value = data as? Int {
            return Decimal(value) as! T
        } else if type == Decimal.self, let value = data as? Double {
            return Decimal(value) as! T
        } else {
            let decoder = _FirestoreDecoder(type, from: data, passthroughTypes: decoder.passthroughTypes, manager: manager)
            return try T(from: decoder)
        }
    }
}
