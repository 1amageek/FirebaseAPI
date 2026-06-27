import FirestoreCore

enum QueryPredicateAnalyzer {
    static let maximumTrackedDisjunctionCount = 101
    private static let maximumNotInValueCount = 10

    static func analyze(_ predicate: QueryPredicate) throws -> PredicateAnalysis {
        switch predicate {
        case .and(let predicates):
            return try analyzeAND(predicates)

        case .or(let predicates):
            return try analyzeOR(predicates)

        case .isEqualTo(_, _),
             .isEqualToDocumentID(_):
            return .single(filterCount: 1)

        case .isNotEqualTo(let field, _):
            return try .single(
                filterCount: 1,
                stats: QueryStats(
                    notEqualCount: 1,
                    rangeOrInequalityFields: [normalizeField(field)]
                )
            )

        case .isNotEqualToDocumentID(_):
            return .single(
                filterCount: 1,
                stats: QueryStats(
                    notEqualCount: 1,
                    rangeOrInequalityFields: ["__name__"]
                )
            )

        case .isLessThan(let field, _),
             .isLessThanOrEqualTo(let field, _),
             .isGreaterThan(let field, _),
             .isGreaterThanOrEqualTo(let field, _):
            return try .single(
                filterCount: 1,
                stats: QueryStats(rangeOrInequalityFields: [normalizeField(field)])
            )

        case .isLessThanDocumentID(_),
             .isLessThanOrEqualToDocumentID(_),
             .isGreaterThanDocumentID(_),
             .isGreaterThanOrEqualToDocumentID(_):
            return .single(
                filterCount: 1,
                stats: QueryStats(rangeOrInequalityFields: ["__name__"])
            )

        case .isIn(_, let values):
            return try disjunctiveArrayAnalysis(
                operatorName: "in",
                valueCount: values.count,
                stats: QueryStats(inCount: 1)
            )

        case .isInDocumentID(let values):
            return try disjunctiveArrayAnalysis(
                operatorName: "in",
                valueCount: values.count,
                stats: QueryStats(inCount: 1)
            )

        case .isNotIn(let field, let values):
            return try notInAnalysis(field: field, valueCount: values.count)

        case .isNotInDocumentID(let values):
            return try notInAnalysis(field: "__name__", valueCount: values.count)

        case .arrayContains(_, _),
             .arrayContainsDocumentID(_):
            return .single(
                filterCount: 1,
                term: DNFConjunction(filterCount: 1, arrayContainsCount: 1)
            )

        case .arrayContainsAny(_, let values):
            return try disjunctiveArrayAnalysis(
                operatorName: "arrayContainsAny",
                valueCount: values.count,
                term: DNFConjunction(
                    filterCount: 1,
                    arrayContainsCount: 1,
                    arrayContainsAnyCount: 1
                ),
                stats: QueryStats(arrayContainsAnyCount: 1)
            )

        case .arrayContainsAnyDocumentID(let values):
            return try disjunctiveArrayAnalysis(
                operatorName: "arrayContainsAny",
                valueCount: values.count,
                term: DNFConjunction(
                    filterCount: 1,
                    arrayContainsCount: 1,
                    arrayContainsAnyCount: 1
                ),
                stats: QueryStats(arrayContainsAnyCount: 1)
            )

        case .orderBy,
             .limitTo,
             .limitToLast,
             .startAt,
             .startAfter,
             .endAt,
             .endBefore,
             .findNearest:
            throw FirestoreError.invalidQuery("Composite query predicates can contain only filters.")
        }
    }

    private static func analyzeAND(_ predicates: [QueryPredicate]) throws -> PredicateAnalysis {
        guard !predicates.isEmpty else {
            throw FirestoreError.invalidQuery("AND query requires at least one filter.")
        }

        var analysis = PredicateAnalysis.identity
        for predicate in predicates {
            analysis = try analysis.combinedWithAND(try analyze(predicate))
        }
        return analysis
    }

    private static func analyzeOR(_ predicates: [QueryPredicate]) throws -> PredicateAnalysis {
        guard !predicates.isEmpty else {
            throw FirestoreError.invalidQuery("OR query requires at least one filter.")
        }

        var analysis = PredicateAnalysis.emptyOR
        for predicate in predicates {
            analysis = analysis.combinedWithOR(try analyze(predicate))
        }
        analysis.stats.hasExplicitOR = true
        return analysis
    }

    private static func disjunctiveArrayAnalysis(
        operatorName: String,
        valueCount: Int,
        term: DNFConjunction = DNFConjunction(filterCount: 1),
        stats: QueryStats
    ) throws -> PredicateAnalysis {
        guard valueCount > 0 else {
            throw FirestoreError.invalidQuery("'\(operatorName)' requires a non-empty array value.")
        }

        return PredicateAnalysis(
            terms: Array(repeating: term, count: min(valueCount, maximumTrackedDisjunctionCount)),
            disjunctionCount: valueCount,
            stats: stats
        )
    }

    private static func notInAnalysis(field: String, valueCount: Int) throws -> PredicateAnalysis {
        guard valueCount > 0 else {
            throw FirestoreError.invalidQuery("'notIn' requires a non-empty array value.")
        }
        guard valueCount <= maximumNotInValueCount else {
            throw FirestoreError.invalidQuery("'notIn' supports at most 10 comparison values.")
        }

        return try .single(
            filterCount: 1,
            stats: QueryStats(
                notInCount: 1,
                rangeOrInequalityFields: [normalizeField(field)]
            )
        )
    }

    private static func normalizeField(_ field: String) throws -> String {
        try FirestoreFieldPath.normalize(field)
    }
}

struct PredicateAnalysis {
    var terms: [DNFConjunction]
    var disjunctionCount: Int
    var stats: QueryStats

    static let identity = PredicateAnalysis(
        terms: [DNFConjunction()],
        disjunctionCount: 1,
        stats: QueryStats()
    )

    static let emptyOR = PredicateAnalysis(
        terms: [],
        disjunctionCount: 0,
        stats: QueryStats()
    )

    static func single(
        filterCount: Int,
        term: DNFConjunction? = nil,
        stats: QueryStats = QueryStats()
    ) -> PredicateAnalysis {
        let resolvedTerm = term ?? DNFConjunction(filterCount: filterCount)
        return PredicateAnalysis(
            terms: [resolvedTerm],
            disjunctionCount: 1,
            stats: stats
        )
    }

    func combinedWithAND(_ other: PredicateAnalysis) throws -> PredicateAnalysis {
        let count = cappedProduct(disjunctionCount, other.disjunctionCount)
        var mergedTerms: [DNFConjunction] = []

        for leftTerm in terms {
            for rightTerm in other.terms {
                mergedTerms.append(leftTerm.merged(with: rightTerm))
                if mergedTerms.count >= QueryPredicateAnalyzer.maximumTrackedDisjunctionCount {
                    break
                }
            }
            if mergedTerms.count >= QueryPredicateAnalyzer.maximumTrackedDisjunctionCount {
                break
            }
        }

        return PredicateAnalysis(
            terms: mergedTerms,
            disjunctionCount: count,
            stats: stats.merged(with: other.stats)
        )
    }

    func combinedWithOR(_ other: PredicateAnalysis) -> PredicateAnalysis {
        var mergedTerms = terms
        let remainingCapacity = QueryPredicateAnalyzer.maximumTrackedDisjunctionCount - mergedTerms.count
        if remainingCapacity > 0 {
            mergedTerms.append(contentsOf: other.terms.prefix(remainingCapacity))
        }

        var mergedStats = stats.merged(with: other.stats)
        mergedStats.hasExplicitOR = stats.hasExplicitOR || other.stats.hasExplicitOR

        return PredicateAnalysis(
            terms: mergedTerms,
            disjunctionCount: cappedSum(disjunctionCount, other.disjunctionCount),
            stats: mergedStats
        )
    }

    private func cappedProduct(_ lhs: Int, _ rhs: Int) -> Int {
        guard lhs > 0, rhs > 0 else {
            return 0
        }
        if lhs > QueryPredicateAnalyzer.maximumTrackedDisjunctionCount / rhs {
            return QueryPredicateAnalyzer.maximumTrackedDisjunctionCount
        }
        return min(lhs * rhs, QueryPredicateAnalyzer.maximumTrackedDisjunctionCount)
    }

    private func cappedSum(_ lhs: Int, _ rhs: Int) -> Int {
        min(lhs + rhs, QueryPredicateAnalyzer.maximumTrackedDisjunctionCount)
    }
}

struct DNFConjunction {
    var filterCount: Int = 0
    var arrayContainsCount: Int = 0
    var arrayContainsAnyCount: Int = 0

    func merged(with other: DNFConjunction) -> DNFConjunction {
        DNFConjunction(
            filterCount: filterCount + other.filterCount,
            arrayContainsCount: arrayContainsCount + other.arrayContainsCount,
            arrayContainsAnyCount: arrayContainsAnyCount + other.arrayContainsAnyCount
        )
    }
}

struct QueryStats {
    var hasExplicitOR: Bool = false
    var inCount: Int = 0
    var arrayContainsAnyCount: Int = 0
    var notInCount: Int = 0
    var notEqualCount: Int = 0
    var rangeOrInequalityFields: Set<String> = []

    func merged(with other: QueryStats) -> QueryStats {
        QueryStats(
            hasExplicitOR: hasExplicitOR || other.hasExplicitOR,
            inCount: inCount + other.inCount,
            arrayContainsAnyCount: arrayContainsAnyCount + other.arrayContainsAnyCount,
            notInCount: notInCount + other.notInCount,
            notEqualCount: notEqualCount + other.notEqualCount,
            rangeOrInequalityFields: rangeOrInequalityFields.union(other.rangeOrInequalityFields)
        )
    }
}
