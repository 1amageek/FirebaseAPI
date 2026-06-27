import Foundation

struct _FirestoreUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    var codingPath: [CodingKey] { encoder.codingPath }

    var count: Int { data.count }

    var encoder: _FirestoreEncoder

    var data: [Any] = [] {
        didSet { encoder.data = data }
    }

    mutating func encodeNil() throws {
        data.append(NSNull())
    }

    mutating func encode(_ value: Bool) throws {
        data.append(value)
    }

    mutating func encode(_ value: Int) throws {
        data.append(value)
    }

    mutating func encode(_ value: Int8) throws {
        data.append(value)
    }

    mutating func encode(_ value: Int16) throws {
        data.append(value)
    }

    mutating func encode(_ value: Int32) throws {
        data.append(value)
    }

    mutating func encode(_ value: Int64) throws {
        data.append(value)
    }

    mutating func encode(_ value: UInt) throws {
        data.append(value)
    }

    mutating func encode(_ value: UInt8) throws {
        data.append(value)
    }

    mutating func encode(_ value: UInt16) throws {
        data.append(value)
    }

    mutating func encode(_ value: UInt32) throws {
        data.append(value)
    }

    mutating func encode(_ value: UInt64) throws {
        data.append(value)
    }

    mutating func encode(_ value: Float) throws {
        data.append(value)
    }

    mutating func encode(_ value: Double) throws {
        data.append(value)
    }

    mutating func encode(_ value: String) throws {
        data.append(value)
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        if encoder.passthroughTypes.contains(where: { type(of: value) == $0 }) {
            data.append(value)
        } else if let date = value as? Date {
            data.append(date.firestoreTimestamp)
        } else if let decimal = value as? Decimal {
            let value = Double(truncating: NSDecimalNumber(decimal: decimal))
            data.append(value)
        } else if let url = value as? URL {
            let value = url.absoluteString
            data.append(value)
        } else {
            let subencoder = _FirestoreEncoder(codingPath: codingPath, passthroughTypes: encoder.passthroughTypes)
            subencoder.codingPath = encoder.codingPath
            try value.encode(to: subencoder)
            data.append(subencoder.data ?? NSNull())
        }
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy keyType: NestedKey.Type
    ) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        let container = FirestoreKeyedEncodingContainer<NestedKey>(encoder: encoder)
        data.append(container.data)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let nestedEncoder = _FirestoreEncoder(codingPath: codingPath, passthroughTypes: encoder.passthroughTypes)
        nestedEncoder.codingPath = codingPath
        let nestedContainer = _FirestoreUnkeyedEncodingContainer(encoder: nestedEncoder)
        data.append(nestedContainer.data)
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }
}
