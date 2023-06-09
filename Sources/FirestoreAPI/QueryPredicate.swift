//
//  QueryPredicate.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation


public enum QueryPredicate {

    enum PredicateType {
        case fieldFilter
        case compositeFilter
        case unaryFilter
        case limit
        case order
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

    var type: PredicateType {
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

public func == (field: String, value: Any) -> QueryPredicate {
    return .isEqualTo(field, value)
}

public func != (field: String, value: Any) -> QueryPredicate {
    return .isNotEqualTo(field, value)
}

public func < (field: String, value: Any) -> QueryPredicate {
    return .isLessThan(field, value)
}

public func <= (field: String, value: Any) -> QueryPredicate {
    return .isLessThanOrEqualTo(field, value)
}

public func > (field: String, value: Any) -> QueryPredicate {
    return .isGreaterThan(field, value)
}

public func >= (field: String, value: Any) -> QueryPredicate {
    return .isGreaterThanOrEqualTo(field, value)
}

public func ~= <T: RangeExpression>(field: String, range: Range<T>) -> QueryPredicate {
    return .and([
        (field >= range.lowerBound),
        (field < range.upperBound)
    ])
}

public func ~= <T: RangeExpression>(field: String, range: ClosedRange<T>) -> QueryPredicate {
    return .and([
        (field >= range.lowerBound),
        (field <= range.upperBound)
    ])
}

public func ~= <T: RangeExpression>(field: String, range: PartialRangeFrom<T>) -> QueryPredicate {
    return (field >= range.lowerBound)
}
