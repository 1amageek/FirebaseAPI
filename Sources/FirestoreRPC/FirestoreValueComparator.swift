//
//  FirestoreValueComparator.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package enum FirestoreValueComparator {
    package static func compare(
        _ lhs: Google_Firestore_V1_Value?,
        _ rhs: Google_Firestore_V1_Value?
    ) -> ComparisonResult {
        switch (lhs?.valueType, rhs?.valueType) {
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        case (.some(let lhsType), .some(let rhsType)):
            return compare(lhsType, rhsType)
        }
    }

    private static func compare(
        _ lhs: Google_Firestore_V1_Value.OneOf_ValueType,
        _ rhs: Google_Firestore_V1_Value.OneOf_ValueType
    ) -> ComparisonResult {
        let lhsRank = typeRank(lhs)
        let rhsRank = typeRank(rhs)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank ? .orderedAscending : .orderedDescending
        }

        switch (lhs, rhs) {
        case (.nullValue, .nullValue):
            return .orderedSame
        case (.booleanValue(let lhsValue), .booleanValue(let rhsValue)):
            return compareBooleans(lhsValue, rhsValue)
        case (.integerValue(let lhsValue), .integerValue(let rhsValue)):
            return compareNumbers(Double(lhsValue), Double(rhsValue))
        case (.integerValue(let lhsValue), .doubleValue(let rhsValue)):
            return compareNumbers(Double(lhsValue), rhsValue)
        case (.doubleValue(let lhsValue), .integerValue(let rhsValue)):
            return compareNumbers(lhsValue, Double(rhsValue))
        case (.doubleValue(let lhsValue), .doubleValue(let rhsValue)):
            return compareNumbers(lhsValue, rhsValue)
        case (.timestampValue(let lhsValue), .timestampValue(let rhsValue)):
            return compareTimestamps(lhsValue, rhsValue)
        case (.stringValue(let lhsValue), .stringValue(let rhsValue)):
            return compareComparable(lhsValue, rhsValue)
        case (.bytesValue(let lhsValue), .bytesValue(let rhsValue)):
            return compareBytes(lhsValue, rhsValue)
        case (.referenceValue(let lhsValue), .referenceValue(let rhsValue)):
            return compareComparable(lhsValue, rhsValue)
        case (.geoPointValue(let lhsValue), .geoPointValue(let rhsValue)):
            return compareGeoPoints(lhsValue, rhsValue)
        case (.arrayValue(let lhsValue), .arrayValue(let rhsValue)):
            return compareArrays(lhsValue.values, rhsValue.values)
        case (.mapValue(let lhsValue), .mapValue(let rhsValue)):
            return compareMaps(lhsValue.fields, rhsValue.fields)
        default:
            return .orderedSame
        }
    }

    private static func typeRank(_ valueType: Google_Firestore_V1_Value.OneOf_ValueType) -> Int {
        switch valueType {
        case .nullValue:
            return 0
        case .booleanValue:
            return 1
        case .integerValue, .doubleValue:
            return 2
        case .timestampValue:
            return 3
        case .stringValue:
            return 4
        case .bytesValue:
            return 5
        case .referenceValue:
            return 6
        case .geoPointValue:
            return 7
        case .arrayValue:
            return 8
        case .mapValue:
            return 9
        case .fieldReferenceValue:
            return 10
        case .variableReferenceValue:
            return 11
        case .functionValue:
            return 12
        case .pipelineValue:
            return 13
        }
    }

    private static func compareBooleans(_ lhs: Bool, _ rhs: Bool) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs ? .orderedDescending : .orderedAscending
    }

    private static func compareNumbers(_ lhs: Double, _ rhs: Double) -> ComparisonResult {
        if lhs.isNaN && rhs.isNaN {
            return .orderedSame
        }
        if lhs.isNaN {
            return .orderedAscending
        }
        if rhs.isNaN {
            return .orderedDescending
        }
        return compareComparable(lhs, rhs)
    }

    private static func compareTimestamps(
        _ lhs: Google_Protobuf_Timestamp,
        _ rhs: Google_Protobuf_Timestamp
    ) -> ComparisonResult {
        let secondsComparison = compareComparable(lhs.seconds, rhs.seconds)
        if secondsComparison != .orderedSame {
            return secondsComparison
        }
        return compareComparable(lhs.nanos, rhs.nanos)
    }

    private static func compareBytes(_ lhs: Data, _ rhs: Data) -> ComparisonResult {
        let lhsBytes = [UInt8](lhs)
        let rhsBytes = [UInt8](rhs)
        let commonCount = min(lhsBytes.count, rhsBytes.count)

        for index in 0..<commonCount {
            let comparison = compareComparable(lhsBytes[index], rhsBytes[index])
            if comparison != .orderedSame {
                return comparison
            }
        }

        return compareComparable(lhsBytes.count, rhsBytes.count)
    }

    private static func compareGeoPoints(
        _ lhs: Google_Type_LatLng,
        _ rhs: Google_Type_LatLng
    ) -> ComparisonResult {
        let latitudeComparison = compareNumbers(lhs.latitude, rhs.latitude)
        if latitudeComparison != .orderedSame {
            return latitudeComparison
        }
        return compareNumbers(lhs.longitude, rhs.longitude)
    }

    private static func compareArrays(
        _ lhs: [Google_Firestore_V1_Value],
        _ rhs: [Google_Firestore_V1_Value]
    ) -> ComparisonResult {
        let commonCount = min(lhs.count, rhs.count)

        for index in 0..<commonCount {
            let comparison = compare(lhs[index], rhs[index])
            if comparison != .orderedSame {
                return comparison
            }
        }

        return compareComparable(lhs.count, rhs.count)
    }

    private static func compareMaps(
        _ lhs: [String: Google_Firestore_V1_Value],
        _ rhs: [String: Google_Firestore_V1_Value]
    ) -> ComparisonResult {
        let lhsKeys = lhs.keys.sorted()
        let rhsKeys = rhs.keys.sorted()
        let commonCount = min(lhsKeys.count, rhsKeys.count)

        for index in 0..<commonCount {
            let keyComparison = compareComparable(lhsKeys[index], rhsKeys[index])
            if keyComparison != .orderedSame {
                return keyComparison
            }

            let key = lhsKeys[index]
            let comparison = compare(lhs[key], rhs[key])
            if comparison != .orderedSame {
                return comparison
            }
        }

        return compareComparable(lhsKeys.count, rhsKeys.count)
    }

    private static func compareComparable<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs < rhs {
            return .orderedAscending
        }
        if lhs > rhs {
            return .orderedDescending
        }
        return .orderedSame
    }
}

extension ComparisonResult {
    package var reversed: ComparisonResult {
        switch self {
        case .orderedAscending:
            return .orderedDescending
        case .orderedSame:
            return .orderedSame
        case .orderedDescending:
            return .orderedAscending
        }
    }
}
