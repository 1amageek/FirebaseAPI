import Foundation
import FirestoreCore

package struct PipelineStage: Sendable {
    package let name: String
    package let arguments: [PipelineValue]
    package let options: [String: PipelineValue]

    package init(
        name: String,
        arguments: [PipelineValue] = [],
        options: [String: PipelineValue] = [:]
    ) {
        self.name = name
        self.arguments = arguments
        self.options = options
    }
}
