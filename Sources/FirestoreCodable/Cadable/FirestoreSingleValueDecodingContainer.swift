import Foundation

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
        try firestoreDecodeDouble(from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Float.Type) throws -> Float {
        try firestoreDecodeFloat(from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Int.Type) throws -> Int {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try firestoreDecodeInteger(type, from: data, codingPath: codingPath, manager: manager)
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let specialValue = try firestoreDecodeSpecialValue(
            type,
            from: data,
            decoder: decoder,
            codingPath: codingPath,
            manager: manager
        ) {
            return specialValue
        }

        let decoder = _FirestoreDecoder(type, from: data, passthroughTypes: decoder.passthroughTypes, manager: manager)
        return try T(from: decoder)
    }
}
