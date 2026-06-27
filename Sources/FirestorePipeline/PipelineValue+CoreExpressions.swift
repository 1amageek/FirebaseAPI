import Foundation
import FirestoreCore

extension PipelineValue {
    public static func constant(_ value: Bool) -> PipelineValue {
        .bool(value)
    }

    public static func constant(_ value: Int) -> PipelineValue {
        .int(Int64(value))
    }

    public static func constant(_ value: Int64) -> PipelineValue {
        .int(value)
    }

    public static func constant(_ value: Double) -> PipelineValue {
        .double(value)
    }

    public static func constant(_ value: String) -> PipelineValue {
        .string(value)
    }

    public static func constant(_ value: Timestamp) -> PipelineValue {
        .timestamp(value)
    }

    public static func constant(_ value: Date) -> PipelineValue {
        .timestamp(Timestamp(value))
    }

    public static func constant(_ value: GeoPoint) -> PipelineValue {
        .geoPoint(value)
    }

    public static func geoPoint(latitude: Double, longitude: Double) -> PipelineValue {
        .geoPoint(GeoPoint(latitude: latitude, longitude: longitude))
    }

    public static func vector(_ vector: FirestoreVector) -> PipelineValue {
        .array(vector.values.map(PipelineValue.double))
    }

    public static func vector(_ values: [Double]) -> PipelineValue {
        .vector(FirestoreVector(values))
    }

    public static func vector(_ values: PipelineValue...) -> PipelineValue {
        vectorExpression(values)
    }

    public static func vectorExpression(_ values: [PipelineValue]) -> PipelineValue {
        .function("vector", [.array(values)])
    }

    public static func path(_ value: PipelineValue) -> PipelineValue {
        .function("path", [value])
    }

    public static func path(_ value: String) -> PipelineValue {
        path(.string(value))
    }

    public static func reference(_ document: DocumentReference) -> PipelineValue {
        .documentReference(document)
    }

    public static func rand() -> PipelineValue {
        .function("rand")
    }

    public static func currentDocument() -> PipelineValue {
        .function("current_document")
    }

    public static func documentMatches(_ query: String) -> PipelineValue {
        .function("document_matches", [.string(query)])
    }

    public static func score() -> PipelineValue {
        .function("score")
    }

    public func geoDistance(to point: GeoPoint) -> PipelineValue {
        geoDistance(to: .geoPoint(point))
    }

    public func geoDistance(to point: PipelineValue) -> PipelineValue {
        .function("geo_distance", [self, point])
    }

    public static func field(_ fieldPath: FieldPath) throws -> PipelineValue {
        .field(try fieldPath.rpcFieldPath())
    }

    public static func lambda(parameters: [String], body: PipelineValue) -> PipelineValue {
        .function("lambda", [.array(parameters.map(PipelineValue.string)), body])
    }

    public func `as`(_ alias: String) -> PipelineValue {
        .function("as", [self, .string(alias)])
    }
}
