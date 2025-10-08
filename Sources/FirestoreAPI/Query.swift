//
//  Query.swift
//
//
//  Created by nori on 2022/05/16.
//

import Foundation
import GRPCCore
import SwiftProtobuf

public struct Query {
    
    var database: Database
    var parentPath: String?
    public var collectionID: String
    var allDescendants: Bool
    var predicates: [QueryPredicate]
    
    public var path: String {
        if let parentPath {
            return "\(parentPath)/\(collectionID)".normalized
        } else {
            return "\(collectionID)".normalized
        }
    }
    
    init(_ database: Database, parentPath: String?, collectionID: String, allDescendants: Bool = false, predicates: [QueryPredicate]) {
        self.database = database
        self.parentPath = parentPath
        self.allDescendants = allDescendants
        self.collectionID = collectionID
        self.predicates = predicates
    }
    
    public func getDocuments<Transport: ClientTransport>(firestore: Firestore<Transport>) async throws -> QuerySnapshot {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocuments(firestore: firestore, metadata: metadata)
    }

    public func getDocuments<T: Decodable, Transport: ClientTransport>(type: T.Type, firestore: Firestore<Transport>) async throws -> [T] {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        var metadata: Metadata = [:]
        metadata.addString("Bearer \(accessToken)", forKey: "authorization")
        return try await getDocuments(type: type, firestore: firestore, metadata: metadata)
    }
}

extension Query {
    var name: String {
        if let parentPath {
            return "\(database.path)/\(parentPath)".normalized
        }
        return "\(database.path)".normalized
    }
}

extension Query {
    public func or(_ filters: [QueryPredicate]) -> Query {
        var predicates: [QueryPredicate] = []
        predicates.append(.or(filters))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func and(_ filters: [QueryPredicate]) -> Query {
        var predicates: [QueryPredicate] = []
        predicates.append(.and(filters))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
}

extension Query {
    func append(_ predicate: QueryPredicate) -> [QueryPredicate] {
        var predicates = self.predicates
        if let compositeFilter = predicates.first(where: { $0.type == .compositeFilter }) {
            if case .and(let filters) = compositeFilter {
                let index = predicates.firstIndex(where: { $0.type == .compositeFilter })!
                var newFilters = filters
                newFilters.append(predicate)
                predicates[index] = .and(newFilters)
                return predicates
            }
            if case .or(_) = compositeFilter {
                let index = predicates.firstIndex(where: { $0.type == .compositeFilter })!
                predicates[index] = .and([compositeFilter, predicate])
                return predicates
            }
        } else if let filter = predicates.first(where: { $0.type == .fieldFilter || $0.type == .unaryFilter }) {
            return [.and([filter, predicate])]
        }
        predicates.append(predicate)
        return predicates
    }
    
    public func `where`(field: String, isEqualTo value: Any) -> Query {
        let predicates = append(.isEqualTo(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, isNotEqualTo value: Any) -> Query {
        let predicates = append(.isNotEqualTo(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, isLessThan value: Any) -> Query {
        let predicates = append(.isLessThan(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, isLessThanOrEqualTo value: Any) -> Query {
        let predicates = append(.isLessThanOrEqualTo(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, isGreaterThan value: Any) -> Query {
        let predicates = append(.isGreaterThan(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, isGreaterThanOrEqualTo value: Any) -> Query {
        let predicates = append(.isGreaterThanOrEqualTo(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, arrayContains value: Any) -> Query {
        let predicates = append(.arrayContains(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, arrayContainsAny value: [Any]) -> Query {
        let predicates = append(.arrayContainsAny(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, in value: [Any]) -> Query {
        let predicates = append(.isIn(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(field: String, notIn value: [Any]) -> Query {
        let predicates = append(.isNotIn(field, value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isEqualTo value: String) -> Query {
        let predicates = append(.isEqualToDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isNotEqualTo value: String) -> Query {
        let predicates = append(.isNotEqualToDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isLessThan value: String) -> Query {
        let predicates = append(.isLessThanDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isLessThanOrEqualTo value: String) -> Query {
        let predicates = append(.isLessThanOrEqualToDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isGreaterThan value: String) -> Query {
        let predicates = append(.isGreaterThanDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(isGreaterThanOrEqualTo value: String) -> Query {
        let predicates = append(.isGreaterThanOrEqualToDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(arrayContains value: String) -> Query {
        let predicates = append(.arrayContainsDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(arrayContainsAny value: [String]) -> Query {
        let predicates = append(.arrayContainsAnyDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(in value: [String]) -> Query {
        let predicates = append(.isInDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func `where`(notIn value: [String]) -> Query {
        let predicates = append(.isNotInDocumentID(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
}

extension Query {
    public func limit(to value: Int) -> Query {
        var predicates = self.predicates
        predicates.append(.limitTo(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
    
    public func limit(toLast value: Int) -> Query {
        var predicates = self.predicates
        predicates.append(.limitToLast(value))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
}

extension Query {
    public func order(by field: String, descending: Bool = false) -> Query {
        var predicates = self.predicates
        predicates.append(.orderBy(field, descending))
        return .init(database, parentPath: parentPath, collectionID: collectionID, allDescendants: allDescendants, predicates: predicates)
    }
}
