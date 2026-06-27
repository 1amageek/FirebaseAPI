import Foundation
import FirestoreCore

public struct FirestorePipeline: Sendable {
    package let stages: [PipelineStage]

    public init() {
        self.stages = []
    }

    package init(stages: [PipelineStage]) {
        self.stages = stages
    }

    public func stage(
        _ name: String,
        arguments: [PipelineValue] = [],
        options: [String: PipelineValue] = [:]
    ) -> FirestorePipeline {
        var stages = self.stages
        stages.append(PipelineStage(name: name, arguments: arguments, options: options))
        return FirestorePipeline(stages: stages)
    }

    public func collection(_ path: String) -> FirestorePipeline {
        stage("collection", arguments: [.string(path)])
    }

    public func collectionGroup(_ collectionID: String) -> FirestorePipeline {
        stage("collection_group", arguments: [.string(collectionID)])
    }

    public func database() -> FirestorePipeline {
        stage("database")
    }

    public func documents(_ documents: [DocumentReference]) -> FirestorePipeline {
        stage("documents", arguments: documents.map(PipelineValue.reference))
    }

    public func literals(_ documents: [[String: PipelineValue]]) -> FirestorePipeline {
        stage("literals", arguments: documents.map(PipelineValue.map))
    }

    public func subcollection(_ collectionID: String) -> FirestorePipeline {
        stage("subcollection", arguments: [.string(collectionID)])
    }

    public func `where`(_ expression: PipelineValue) -> FirestorePipeline {
        stage("where", arguments: [expression])
    }

    public func search(
        query: PipelineValue,
        sort: [PipelineValue] = [],
        addFields: [PipelineValue] = []
    ) -> FirestorePipeline {
        var options: [String: PipelineValue] = [
            "query": query
        ]
        if !sort.isEmpty {
            options["sort"] = .array(sort)
        }
        if !addFields.isEmpty {
            options["add_fields"] = .array(addFields)
        }
        return stage("search", options: options)
    }

    public func search(
        query: String,
        sort: [PipelineValue] = [],
        addFields: [PipelineValue] = []
    ) -> FirestorePipeline {
        search(query: .documentMatches(query), sort: sort, addFields: addFields)
    }

    public func findNearest(
        field: String,
        vectorValue: FirestoreVector,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        limit: Int? = nil,
        distanceField: String? = nil
    ) -> FirestorePipeline {
        var options: [String: PipelineValue] = [
            "field": .field(field),
            "vector_value": .vector(vectorValue),
            "distance_measure": .string(distanceMeasure.rawValue)
        ]
        if let limit {
            options["limit"] = .int(Int64(limit))
        }
        if let distanceField {
            options["distance_field"] = .string(distanceField)
        }
        return stage("find_nearest", options: options)
    }

    public func findNearest(
        field: FieldPath,
        vectorValue: FirestoreVector,
        distanceMeasure: FirestoreVectorDistanceMeasure,
        limit: Int? = nil,
        distanceField: String? = nil
    ) throws -> FirestorePipeline {
        try findNearest(
            field: field.rpcFieldPath(),
            vectorValue: vectorValue,
            distanceMeasure: distanceMeasure,
            limit: limit,
            distanceField: distanceField
        )
    }

    public func limit(_ count: Int64) -> FirestorePipeline {
        stage("limit", arguments: [.int(count)])
    }

    public func offset(_ count: Int64) -> FirestorePipeline {
        stage("offset", arguments: [.int(count)])
    }

    public func select(_ values: [PipelineValue]) -> FirestorePipeline {
        stage("select", arguments: values)
    }

    public func addFields(_ values: [PipelineValue]) -> FirestorePipeline {
        stage("add_fields", arguments: values)
    }

    public func removeFields(_ fields: [String]) -> FirestorePipeline {
        stage("remove_fields", arguments: fields.map(PipelineValue.string))
    }

    public func define(_ assignments: [PipelineValue]) -> FirestorePipeline {
        stage("let", arguments: assignments)
    }

    public func sort(_ orderings: [PipelineValue]) -> FirestorePipeline {
        stage("sort", arguments: orderings)
    }

    public func aggregate(
        _ accumulators: [PipelineValue],
        groups: [PipelineValue] = []
    ) -> FirestorePipeline {
        let options: [String: PipelineValue]
        if groups.isEmpty {
            options = [:]
        } else {
            options = ["groups": .array(groups)]
        }
        return stage("aggregate", arguments: accumulators, options: options)
    }

    public func distinct(_ groups: [PipelineValue]) -> FirestorePipeline {
        stage("distinct", arguments: groups)
    }

    public func replaceWith(
        _ value: PipelineValue,
        mode: PipelineReplaceMode = .fullReplace
    ) -> FirestorePipeline {
        stage("replace_with", arguments: [value, .string(mode.rawValue)])
    }

    public func update(_ transformations: [PipelineValue] = []) -> FirestorePipeline {
        stage("update", arguments: transformations)
    }

    public func delete() -> FirestorePipeline {
        stage("delete")
    }

    public func sample(count: Int64) -> FirestorePipeline {
        stage("sample", arguments: [.int(count)])
    }

    public func sample(percentage: Double) -> FirestorePipeline {
        stage("sample", options: ["percentage": .double(percentage)])
    }

    public func unnest(_ value: PipelineValue, indexField: String? = nil) -> FirestorePipeline {
        if let indexField {
            return stage("unnest", arguments: [value], options: ["index_field": .string(indexField)])
        }
        return stage("unnest", arguments: [value])
    }

    public func union(with pipeline: FirestorePipeline) -> FirestorePipeline {
        stage("union", arguments: [.pipeline(pipeline)])
    }

    public func toArrayExpression() -> PipelineValue {
        .function("array", [.pipeline(self)])
    }

    public func toScalarExpression() -> PipelineValue {
        .function("scalar", [.pipeline(self)])
    }
}
