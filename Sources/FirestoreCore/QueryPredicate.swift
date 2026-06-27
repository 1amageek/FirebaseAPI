//
//  QueryPredicate.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation


package enum QueryPredicate {

    package enum PredicateType {
        case fieldFilter
        case compositeFilter
        case unaryFilter
        case limit
        case order
        case cursor
        case findNearest
    }

    // Field
    case isEqualTo(_ field: String, _ value: Any)
    case isNotEqualTo(_ field: String, _ value: Any)
    case isIn(_ field: String, _ values: [Any])
    case isNotIn(_ field: String, _ values: [Any])
    case arrayContains(_ field: String, _ value: Any)
    case arrayContainsAny(_ field: String, _ values: [Any])
    case isLessThan(_ field: String, _ value: Any)
    case isGreaterThan(_ field: String, _ value: Any)
    case isLessThanOrEqualTo(_ field: String, _ value: Any)
    case isGreaterThanOrEqualTo(_ field: String, _ value: Any)
    case orderBy(_ field: String, _ value: Bool)
    case limitTo(_ value: Int)
    case limitToLast(_ value: Int)
    case startAt(_ values: [Any])
    case startAfter(_ values: [Any])
    case endAt(_ values: [Any])
    case endBefore(_ values: [Any])
    case findNearest(_ query: FirestoreFindNearestQuery)
    case or(_ filters: [QueryPredicate])
    case and(_ filters: [QueryPredicate])

    // DocumentID
    case isEqualToDocumentID(_ value: String)
    case isNotEqualToDocumentID(_ value: String)
    case isInDocumentID(_ values: [String])
    case isNotInDocumentID( _ values: [String])
    case arrayContainsDocumentID(_ value: String)
    case arrayContainsAnyDocumentID(_ values: [String])
    case isLessThanDocumentID(_ value: String)
    case isGreaterThanDocumentID(_ value: String)
    case isLessThanOrEqualToDocumentID(_ value: String)
    case isGreaterThanOrEqualToDocumentID(_ value: String)

    package var type: PredicateType {
        switch self {
            case .or(_): return .compositeFilter
            case .and(_): return .compositeFilter
            case .isEqualTo(_, _): return .fieldFilter
            case .isNotEqualTo(_, _): return .fieldFilter
            case .isIn(_, _): return .fieldFilter
            case .isNotIn(_, _): return .fieldFilter
            case .arrayContains(_, _): return .fieldFilter
            case .arrayContainsAny(_, _): return .fieldFilter
            case .isLessThan(_, _): return .fieldFilter
            case .isGreaterThan(_, _): return .fieldFilter
            case .isLessThanOrEqualTo(_, _): return .fieldFilter
            case .isGreaterThanOrEqualTo(_, _): return .fieldFilter
            case .orderBy(_, _): return .order
            case .limitTo(_): return .limit
            case .limitToLast(_): return .limit
            case .startAt(_): return .cursor
            case .startAfter(_): return .cursor
            case .endAt(_): return .cursor
            case .endBefore(_): return .cursor
            case .findNearest(_): return .findNearest
            case .isEqualToDocumentID(_): return .fieldFilter
            case .isNotEqualToDocumentID(_): return .fieldFilter
            case .isInDocumentID(_): return .fieldFilter
            case .isNotInDocumentID(_): return .fieldFilter
            case .arrayContainsDocumentID(_): return .fieldFilter
            case .arrayContainsAnyDocumentID(_): return .fieldFilter
            case .isLessThanDocumentID(_): return .fieldFilter
            case .isGreaterThanDocumentID(_): return .fieldFilter
            case .isLessThanOrEqualToDocumentID(_): return .fieldFilter
            case .isGreaterThanOrEqualToDocumentID(_): return .fieldFilter
        }
    }
}

package func == (field: String, value: Any) -> QueryPredicate {
    return .isEqualTo(field, value)
}

package func != (field: String, value: Any) -> QueryPredicate {
    return .isNotEqualTo(field, value)
}

package func < (field: String, value: Any) -> QueryPredicate {
    return .isLessThan(field, value)
}

package func <= (field: String, value: Any) -> QueryPredicate {
    return .isLessThanOrEqualTo(field, value)
}

package func > (field: String, value: Any) -> QueryPredicate {
    return .isGreaterThan(field, value)
}

package func >= (field: String, value: Any) -> QueryPredicate {
    return .isGreaterThanOrEqualTo(field, value)
}

package func ~= <T: RangeExpression>(field: String, range: Range<T>) -> QueryPredicate {
    return .and([
        (field >= range.lowerBound),
        (field < range.upperBound)
    ])
}

package func ~= <T: RangeExpression>(field: String, range: ClosedRange<T>) -> QueryPredicate {
    return .and([
        (field >= range.lowerBound),
        (field <= range.upperBound)
    ])
}

package func ~= <T: RangeExpression>(field: String, range: PartialRangeFrom<T>) -> QueryPredicate {
    return (field >= range.lowerBound)
}

extension QueryPredicate {
    package static func field(_ fieldPath: FieldPath, isEqualTo value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isEqualToDocumentID(try documentIDStringValue(value))
        }
        return .isEqualTo(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, isNotEqualTo value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isNotEqualToDocumentID(try documentIDStringValue(value))
        }
        return .isNotEqualTo(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, isLessThan value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isLessThanDocumentID(try documentIDStringValue(value))
        }
        return .isLessThan(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, isLessThanOrEqualTo value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isLessThanOrEqualToDocumentID(try documentIDStringValue(value))
        }
        return .isLessThanOrEqualTo(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, isGreaterThan value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isGreaterThanDocumentID(try documentIDStringValue(value))
        }
        return .isGreaterThan(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, isGreaterThanOrEqualTo value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isGreaterThanOrEqualToDocumentID(try documentIDStringValue(value))
        }
        return .isGreaterThanOrEqualTo(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, arrayContains value: Any) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .arrayContainsDocumentID(try documentIDStringValue(value))
        }
        return .arrayContains(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, arrayContainsAny value: [Any]) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .arrayContainsAnyDocumentID(try documentIDStringArray(value))
        }
        return .arrayContainsAny(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, in value: [Any]) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isInDocumentID(try documentIDStringArray(value))
        }
        return .isIn(try fieldPath.rpcFieldPath(), value)
    }

    package static func field(_ fieldPath: FieldPath, notIn value: [Any]) throws -> QueryPredicate {
        if fieldPath.isDocumentID {
            return .isNotInDocumentID(try documentIDStringArray(value))
        }
        return .isNotIn(try fieldPath.rpcFieldPath(), value)
    }

    package static func findNearest(
        fieldPath: FieldPath,
        queryVector: FirestoreVector,
        limit: Int,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        distanceResultField: String?,
        distanceThreshold: Double?
    ) throws -> QueryPredicate {
        guard !fieldPath.isDocumentID else {
            throw FirestoreError.invalidQuery("FieldPath.documentID cannot be used as a vector field.")
        }
        return .findNearest(
            FirestoreFindNearestQuery(
                vectorField: try fieldPath.rpcFieldPath(),
                queryVector: queryVector,
                limit: limit,
                distanceMeasure: distanceMeasure,
                distanceResultField: distanceResultField,
                distanceThreshold: distanceThreshold
            )
        )
    }

    private static func documentIDStringValue(_ value: Any) throws -> String {
        guard let string = value as? String else {
            throw FirestoreError.invalidQuery("FieldPath.documentID requires String comparison values.")
        }
        return string
    }

    private static func documentIDStringArray(_ values: [Any]) throws -> [String] {
        var strings: [String] = []
        for value in values {
            guard let string = value as? String else {
                throw FirestoreError.invalidQuery("FieldPath.documentID requires String comparison values.")
            }
            strings.append(string)
        }
        return strings
    }
}
