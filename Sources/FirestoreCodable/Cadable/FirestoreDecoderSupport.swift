import Foundation
import FirestoreCore

func firestoreTypeMismatch(
    _ type: Any.Type,
    value: Any,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) -> DecodingError {
    DecodingError.typeMismatch(
        type,
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "\(manager.message) = \(value): Expected a \(type)"
        )
    )
}

func firestoreDataCorrupted(
    _ type: Any.Type,
    value: Any,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) -> DecodingError {
    DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "\(manager.message) = \(value): Expected a valid \(type)"
        )
    )
}

func firestoreValueNotFound(
    _ type: Any.Type,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) -> DecodingError {
    DecodingError.valueNotFound(
        type,
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "\(manager.message): Expected a value of type \(type)"
        )
    )
}

func firestoreCast<T>(
    _ value: Any,
    to type: T.Type,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> T {
    guard let converted = value as? T else {
        throw firestoreTypeMismatch(type, value: value, codingPath: codingPath, manager: manager)
    }
    return converted
}

func firestoreDecodeSpecialValue<T>(
    _ type: T.Type,
    from value: Any,
    decoder: _FirestoreDecoder,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> T? {
    if type == FirestoreVector.self {
        if let vector = value as? FirestoreVector {
            return try firestoreCast(vector, to: type, codingPath: codingPath, manager: manager)
        }
        if let values = value as? [Any] {
            let vectorValues = try values.enumerated().map { index, value in
                try firestoreDecodeDouble(
                    from: value,
                    codingPath: codingPath + [FirestoreKey(index: index)],
                    manager: manager
                )
            }
            return try firestoreCast(
                FirestoreVector(vectorValues),
                to: type,
                codingPath: codingPath,
                manager: manager
            )
        }
    }

    if decoder.passthroughTypes.contains(where: { $0 == type }) {
        return try firestoreCast(value, to: type, codingPath: codingPath, manager: manager)
    }

    if type == Date.self {
        if let timestamp = value as? Timestamp {
            return try firestoreCast(
                firestoreDate(from: timestamp),
                to: type,
                codingPath: codingPath,
                manager: manager
            )
        }
        if let string = value as? String {
            guard let date = decoder.dateForamatter.date(from: string) else {
                throw firestoreDataCorrupted(type, value: value, codingPath: codingPath, manager: manager)
            }
            return try firestoreCast(date, to: type, codingPath: codingPath, manager: manager)
        }
    }

    if type == Decimal.self {
        if let value = value as? Int {
            return try firestoreCast(Decimal(value), to: type, codingPath: codingPath, manager: manager)
        }
        if let value = value as? Int64 {
            return try firestoreCast(Decimal(value), to: type, codingPath: codingPath, manager: manager)
        }
        if let value = value as? Double {
            return try firestoreCast(Decimal(value), to: type, codingPath: codingPath, manager: manager)
        }
    }

    if type == URL.self, let string = value as? String {
        guard let url = URL(string: string) else {
            throw firestoreDataCorrupted(type, value: value, codingPath: codingPath, manager: manager)
        }
        return try firestoreCast(url, to: type, codingPath: codingPath, manager: manager)
    }

    return nil
}

func firestoreDecodeGeneratedReferenceField<T>(
    _ type: T.Type,
    reference: DocumentReference,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> T? {
    if type == DocumentID<String>.self {
        return try firestoreCast(
            DocumentID(wrappedValue: reference.documentID),
            to: type,
            codingPath: codingPath,
            manager: manager
        )
    }
    if type == ReferencePath<String>.self {
        return try firestoreCast(
            ReferencePath(wrappedValue: reference.path),
            to: type,
            codingPath: codingPath,
            manager: manager
        )
    }
    return nil
}

protocol FirestoreMissingValueDecodable {
    static func firestoreMissingValue() -> Self
}

extension ExplicitNull: FirestoreMissingValueDecodable {
    static func firestoreMissingValue() -> ExplicitNull<Value> {
        ExplicitNull(wrappedValue: nil)
    }
}

extension ServerTimestamp: FirestoreMissingValueDecodable {
    static func firestoreMissingValue() -> ServerTimestamp<Value> {
        ServerTimestamp(wrappedValue: nil)
    }
}

func firestoreDecodeMissingValue<T>(_ type: T.Type) -> T? {
    guard let missingValueType = type as? FirestoreMissingValueDecodable.Type else {
        return nil
    }
    return missingValueType.firestoreMissingValue() as? T
}

func firestoreDecodeInteger<T: FixedWidthInteger>(
    _ type: T.Type,
    from value: Any,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> T {
    if let value = value as? T {
        return value
    }

    let converted: T?
    switch value {
    case let value as Int:
        converted = T(exactly: value)
    case let value as Int8:
        converted = T(exactly: value)
    case let value as Int16:
        converted = T(exactly: value)
    case let value as Int32:
        converted = T(exactly: value)
    case let value as Int64:
        converted = T(exactly: value)
    case let value as UInt:
        converted = T(exactly: value)
    case let value as UInt8:
        converted = T(exactly: value)
    case let value as UInt16:
        converted = T(exactly: value)
    case let value as UInt32:
        converted = T(exactly: value)
    case let value as UInt64:
        converted = T(exactly: value)
    case let value as Double:
        converted = T(exactly: value)
    case let value as Float:
        converted = T(exactly: value)
    default:
        converted = nil
    }

    guard let converted else {
        throw firestoreTypeMismatch(type, value: value, codingPath: codingPath, manager: manager)
    }
    return converted
}

func firestoreDecodeDouble(
    from value: Any,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> Double {
    switch value {
    case let value as Double:
        return value
    case let value as Float:
        return Double(value)
    case let value as Int:
        return Double(value)
    case let value as Int8:
        return Double(value)
    case let value as Int16:
        return Double(value)
    case let value as Int32:
        return Double(value)
    case let value as Int64:
        return Double(value)
    case let value as UInt:
        return Double(value)
    case let value as UInt8:
        return Double(value)
    case let value as UInt16:
        return Double(value)
    case let value as UInt32:
        return Double(value)
    case let value as UInt64:
        return Double(value)
    default:
        throw firestoreTypeMismatch(Double.self, value: value, codingPath: codingPath, manager: manager)
    }
}

func firestoreDecodeFloat(
    from value: Any,
    codingPath: [CodingKey],
    manager: CodingKeyManager
) throws -> Float {
    if let value = value as? Float {
        return value
    }
    let doubleValue = try firestoreDecodeDouble(from: value, codingPath: codingPath, manager: manager)
    if doubleValue.isFinite {
        guard abs(doubleValue) <= Double(Float.greatestFiniteMagnitude) else {
            throw firestoreTypeMismatch(Float.self, value: value, codingPath: codingPath, manager: manager)
        }
    }
    return Float(doubleValue)
}

func firestoreDate(from timestamp: Timestamp) -> Date {
    Date(
        timeIntervalSince1970: TimeInterval(timestamp.seconds)
            + TimeInterval(timestamp.nanos) / 1_000_000_000
    )
}

func firestoreDate(from string: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.timeZone = .autoupdatingCurrent
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    return dateFormatter.date(from: string)
}
