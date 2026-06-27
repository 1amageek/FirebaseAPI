import FirestoreCore
import FirestoreProtobuf

extension ReadResponseMapper {
    func makeAggregateFields(
        from responses: [Google_Firestore_V1_RunAggregationQueryResponse]
    ) throws -> [String: Google_Firestore_V1_Value] {
        for response in responses where response.hasResult {
            return response.result.aggregateFields
        }
        throw FirestoreError.noResult
    }

    package func makeAggregateSnapshot(
        from responses: [Google_Firestore_V1_RunAggregationQueryResponse]
    ) throws -> AggregateQuerySnapshot {
        try makeAggregateSnapshot(from: makeAggregateFields(from: responses))
    }

    func makeAggregateSnapshot(
        from aggregateFields: [String: Google_Firestore_V1_Value]
    ) throws -> AggregateQuerySnapshot {
        var data: [String: AggregateValue] = [:]
        for (alias, value) in aggregateFields {
            data[alias] = try makeAggregateValue(from: value)
        }
        return AggregateQuerySnapshot(data: data)
    }

    func makeAggregateValue(
        from value: Google_Firestore_V1_Value
    ) throws -> AggregateValue {
        switch value.valueType {
        case .integerValue(let value):
            return .integer(value)
        case .doubleValue(let value):
            return .double(value)
        case .nullValue:
            return .null
        default:
            throw FirestoreError.noResult
        }
    }
}
