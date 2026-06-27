import Foundation

struct _FirestoreSingleValueEncodingContainer: SingleValueEncodingContainer {

    var codingPath: [CodingKey] = []

    var encoder: _FirestoreEncoder

    mutating func encodeNil() throws {
        encoder.data = NSNull()
    }

    mutating func encode(_ value: Bool) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Int) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Int8) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Int16) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Int32) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Int64) throws {
        encoder.data = value
    }

    mutating func encode(_ value: UInt) throws {
        encoder.data = value
    }

    mutating func encode(_ value: UInt8) throws {
        encoder.data = value
    }

    mutating func encode(_ value: UInt16) throws {
        encoder.data = value
    }

    mutating func encode(_ value: UInt32) throws {
        encoder.data = value
    }

    mutating func encode(_ value: UInt64) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Float) throws {
        encoder.data = value
    }

    mutating func encode(_ value: Double) throws {
        encoder.data = value
    }

    mutating func encode(_ value: String) throws {
        encoder.data = value
    }

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        if encoder.passthroughTypes.contains(where: { type(of: value) == $0 }) {
            encoder.data = value
        } else {
            let subencoder = _FirestoreEncoder(codingPath: codingPath, passthroughTypes: encoder.passthroughTypes)
            try value.encode(to: subencoder)
            encoder.data = subencoder.data
        }
    }
}
