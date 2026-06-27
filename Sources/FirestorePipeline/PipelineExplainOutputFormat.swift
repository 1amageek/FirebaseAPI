import Foundation
import FirestoreCore

public enum PipelineExplainOutputFormat: String, Sendable, Equatable {
    case text
    case json

    package var rpcValue: String {
        rawValue.uppercased()
    }
}
