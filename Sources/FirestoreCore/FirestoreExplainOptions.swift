import Foundation

public struct FirestoreExplainOptions: Sendable, Equatable {
    public let analyze: Bool

    public init(analyze: Bool = false) {
        self.analyze = analyze
    }

    public static let planOnly = FirestoreExplainOptions(analyze: false)
    public static let analyze = FirestoreExplainOptions(analyze: true)
}
