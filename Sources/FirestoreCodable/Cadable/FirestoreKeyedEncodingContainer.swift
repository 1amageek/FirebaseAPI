import Foundation
import FirestoreCore

struct FirestoreKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {

    typealias Key = K

    var codingPath: [CodingKey] = []

    var encoder: _FirestoreEncoder

    var data: [String: Any] = [:] {
        didSet { encoder.data = data }
    }

    mutating func encodeNil(forKey key: Key) throws {
        data[key.stringValue] = NSNull()
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        data[key.stringValue] = value
    }

    mutating func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        if let value = value as? DocumentID<String> {
            if !codingPath.isEmpty {
                data[key.stringValue] = value.wrappedValue
            }
            return
        }
        if encoder.passthroughTypes.contains(where: { type(of: value) == $0 }) {
            data[key.stringValue] = value
        } else if let date = value as? Date {
            data[key.stringValue] = date.firestoreTimestamp
        } else if let decimal = value as? Decimal {
            let value = Double(truncating: NSDecimalNumber(decimal: decimal))
            data[key.stringValue] = value
        } else if let url = value as? URL {
            let value = url.absoluteString
            data[key.stringValue] = value
        } else {
            codingPath.append(key)
            defer { codingPath.removeLast() }
            let subencoder = _FirestoreEncoder(codingPath: codingPath, passthroughTypes: encoder.passthroughTypes)
            try value.encode(to: subencoder)
            data[key.stringValue] = subencoder.data
        }
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        codingPath.append(key)
        defer { codingPath.removeLast() }
        let container = FirestoreKeyedEncodingContainer<NestedKey>(codingPath: codingPath, encoder: encoder)
        data[key.stringValue] = container.data
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        codingPath.append(key)
        defer { codingPath.removeLast() }
        let unkeyedContainer = _FirestoreUnkeyedEncodingContainer(encoder: encoder)
        data[key.stringValue] = unkeyedContainer.data
        return unkeyedContainer
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        return encoder
    }
}
