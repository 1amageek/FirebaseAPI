import Foundation
import FirestoreCore

public struct PipelineValue: Sendable {
    package indirect enum Storage: Sendable {
        case null
        case bool(Bool)
        case int(Int64)
        case double(Double)
        case string(String)
        case bytes(Data)
        case timestamp(Timestamp)
        case geoPoint(GeoPoint)
        case reference(String)
        case documentReference(DocumentReference)
        case array([PipelineValue])
        case map([String: PipelineValue])
        case field(String)
        case variable(String)
        case function(name: String, arguments: [PipelineValue], options: [String: PipelineValue])
        case pipeline(FirestorePipeline)
    }

    package let storage: Storage

    package init(_ storage: Storage) {
        self.storage = storage
    }

    public static let null = PipelineValue(.null)

    public static func bool(_ value: Bool) -> PipelineValue {
        PipelineValue(.bool(value))
    }

    public static func int(_ value: Int64) -> PipelineValue {
        PipelineValue(.int(value))
    }

    public static func double(_ value: Double) -> PipelineValue {
        PipelineValue(.double(value))
    }

    public static func string(_ value: String) -> PipelineValue {
        PipelineValue(.string(value))
    }

    public static func bytes(_ value: Data) -> PipelineValue {
        PipelineValue(.bytes(value))
    }

    public static func timestamp(_ value: Timestamp) -> PipelineValue {
        PipelineValue(.timestamp(value))
    }

    public static func geoPoint(_ value: GeoPoint) -> PipelineValue {
        PipelineValue(.geoPoint(value))
    }

    package static func reference(_ name: String) -> PipelineValue {
        PipelineValue(.reference(name))
    }

    package static func documentReference(_ document: DocumentReference) -> PipelineValue {
        PipelineValue(.documentReference(document))
    }

    public static func array(_ values: [PipelineValue]) -> PipelineValue {
        PipelineValue(.array(values))
    }

    public static func map(_ values: [String: PipelineValue]) -> PipelineValue {
        PipelineValue(.map(values))
    }

    public static func field(_ fieldPath: String) -> PipelineValue {
        PipelineValue(.field(fieldPath))
    }

    public static func variable(_ name: String) -> PipelineValue {
        PipelineValue(.variable(name))
    }

    package static func pipeline(_ pipeline: FirestorePipeline) -> PipelineValue {
        PipelineValue(.pipeline(pipeline))
    }

    public static func function(
        _ name: String,
        _ arguments: [PipelineValue] = [],
        options: [String: PipelineValue] = [:]
    ) -> PipelineValue {
        PipelineValue(.function(name: name, arguments: arguments, options: options))
    }
}
