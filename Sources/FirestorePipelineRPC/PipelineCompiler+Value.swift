import Foundation
import FirestoreCore
import FirestoreProtobuf
import FirestorePipeline
import SwiftProtobuf

extension PipelineCompiler {
    func makeValue(
        _ value: PipelineValue,
        context: PipelineContext = .topLevel
    ) throws -> Google_Firestore_V1_Value {
        try Google_Firestore_V1_Value.with {
            switch value.storage {
            case .null:
                $0.nullValue = .nullValue
            case .bool(let value):
                $0.booleanValue = value
            case .int(let value):
                $0.integerValue = value
            case .double(let value):
                $0.doubleValue = value
            case .string(let value):
                $0.stringValue = value
            case .bytes(let value):
                $0.bytesValue = value
            case .timestamp(let value):
                $0.timestampValue = Google_Protobuf_Timestamp.with {
                    $0.seconds = value.seconds
                    $0.nanos = value.nanos
                }
            case .geoPoint(let value):
                $0.geoPointValue = Google_Type_LatLng.with {
                    $0.latitude = value.latitude
                    $0.longitude = value.longitude
                }
            case .reference(let value):
                $0.referenceValue = try makeReferenceValue(value)
            case .documentReference(let document):
                try validateDatabase(document.database)
                $0.referenceValue = document.name
            case .array(let values):
                let compiledValues = try values.map { try makeValue($0, context: context) }
                $0.arrayValue = Google_Firestore_V1_ArrayValue.with { $0.values = compiledValues }
            case .map(let values):
                let compiledValues = try values.mapValues { try makeValue($0, context: context) }
                $0.mapValue = Google_Firestore_V1_MapValue.with { $0.fields = compiledValues }
            case .field(let fieldPath):
                $0.fieldReferenceValue = try FirestoreFieldPath.normalize(fieldPath)
            case .variable(let name):
                try validateName(name, label: "Pipeline variable")
                $0.variableReferenceValue = name
            case .function(let name, let arguments, let options):
                try validateName(name, label: "Pipeline function")
                try validateOptionNames(options.keys, label: "Pipeline function option")
                try validateKnownFunctionArguments(name: name, arguments: arguments)
                let nestedContext: PipelineContext = isSubqueryWrapper(name) ? .subquery : .nested
                let compiledArguments = try arguments.map { try makeValue($0, context: nestedContext) }
                let compiledOptions = try options.mapValues { try makeValue($0, context: context) }
                $0.functionValue = Google_Firestore_V1_Function.with {
                    $0.name = name
                    $0.args = compiledArguments
                    $0.options = compiledOptions
                }
            case .pipeline(let pipeline):
                $0.pipelineValue = try makePipeline(pipeline, context: context)
            }
        }
    }

    private func isSubqueryWrapper(_ functionName: String) -> Bool {
        functionName == "array" || functionName == "scalar"
    }

    func makeReferenceValue(_ name: String) throws -> String {
        let reference = try DocumentReference(name: name)
        try validateDatabase(reference.database)
        return reference.name
    }

    func validateDatabase(_ other: Database) throws {
        guard other == database else {
            throw FirestoreError.databaseMismatch(
                expected: database.database,
                actual: other.database
            )
        }
    }

    func validateName(_ name: String, label: String) throws {
        guard !name.isEmpty else {
            throw FirestoreError.invalidQuery("\(label) name must not be empty.")
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        guard name.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw FirestoreError.invalidQuery("\(label) name must be snake_case.")
        }
    }

    func validateOptionNames<Keys: Sequence>(
        _ optionNames: Keys,
        label: String
    ) throws where Keys.Element == String {
        for optionName in optionNames {
            try validateName(optionName, label: label)
        }
    }
}
