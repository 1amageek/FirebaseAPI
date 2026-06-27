import Foundation
import FirestoreCore

package struct QueryConstraintValidator {
    private static let maximumDisjunctionCount = 30
    private static let maximumRangeOrInequalityFieldCount = 10
    private static let maximumFilterSortAndPathComponentCount = 100

    package static func validate(
        predicates: [QueryPredicate],
        orderFields: [String],
        parentPath: String?
    ) throws {
        var analysis = PredicateAnalysis.identity
        for predicate in predicates {
            if predicate.type == .order || predicate.type == .limit || predicate.type == .cursor || predicate.type == .findNearest {
                continue
            }
            analysis = try analysis.combinedWithAND(try QueryPredicateAnalyzer.analyze(predicate))
        }

        try validateDisjunctionCount(analysis.disjunctionCount)
        try validateArrayMembershipRules(analysis.terms)
        try validateNotInRules(analysis.stats)
        try validateRangeAndInequalityRules(
            analysis.stats,
            orderFields: orderFields
        )
        try validateFilterSortAndPathLimit(
            analysis.terms,
            orderCount: orderFields.count,
            parentPath: parentPath
        )
    }

    private static func validateDisjunctionCount(_ count: Int) throws {
        guard count <= maximumDisjunctionCount else {
            throw FirestoreError.invalidQuery("Query expands to \(count) disjunctions; Firestore supports at most 30.")
        }
    }

    private static func validateArrayMembershipRules(_ terms: [DNFConjunction]) throws {
        for term in terms {
            if term.arrayContainsCount > 0 && term.arrayContainsAnyCount > 0 && term.arrayContainsCount > term.arrayContainsAnyCount {
                throw FirestoreError.invalidQuery("arrayContains cannot be combined with arrayContainsAny in the same disjunction.")
            }
            if term.arrayContainsAnyCount > 1 {
                throw FirestoreError.invalidQuery("Use at most one arrayContainsAny filter per disjunction.")
            }
            if term.arrayContainsCount > 1 {
                throw FirestoreError.invalidQuery("Use at most one arrayContains filter per disjunction.")
            }
        }
    }

    private static func validateNotInRules(_ stats: QueryStats) throws {
        let negativeCount = stats.notInCount + stats.notEqualCount
        guard negativeCount <= 1 else {
            throw FirestoreError.invalidQuery("Only a single notIn or notEqual filter is allowed per query.")
        }

        guard stats.notInCount == 0 || !stats.hasExplicitOR else {
            throw FirestoreError.invalidQuery("notIn cannot be combined with OR filters.")
        }
        guard stats.notInCount == 0 || stats.inCount == 0 else {
            throw FirestoreError.invalidQuery("notIn cannot be combined with in filters.")
        }
        guard stats.notInCount == 0 || stats.arrayContainsAnyCount == 0 else {
            throw FirestoreError.invalidQuery("notIn cannot be combined with arrayContainsAny filters.")
        }
    }

    private static func validateRangeAndInequalityRules(
        _ stats: QueryStats,
        orderFields: [String]
    ) throws {
        guard stats.rangeOrInequalityFields.count <= maximumRangeOrInequalityFieldCount else {
            throw FirestoreError.invalidQuery("Firestore supports at most 10 range or inequality fields per query.")
        }

        guard !stats.rangeOrInequalityFields.isEmpty, let firstOrderField = orderFields.first else {
            return
        }

        let normalizedFirstOrderField = try normalizeField(firstOrderField)
        guard stats.rangeOrInequalityFields.contains(normalizedFirstOrderField) else {
            throw FirestoreError.invalidQuery("The first orderBy field must match a range or inequality filter field.")
        }
    }

    private static func validateFilterSortAndPathLimit(
        _ terms: [DNFConjunction],
        orderCount: Int,
        parentPath: String?
    ) throws {
        let parentPathCost = parentPath == nil ? 0 : 1
        for term in terms {
            let componentCount = term.filterCount + orderCount + parentPathCost
            guard componentCount <= maximumFilterSortAndPathComponentCount else {
                throw FirestoreError.invalidQuery("The sum of filters, sort orders, and parent document path components cannot exceed 100.")
            }
        }
    }

    private static func normalizeField(_ field: String) throws -> String {
        try FirestoreFieldPath.normalize(field)
    }
}
