import FirestoreCore
public struct PipelineTimestampUnit: RawRepresentable, Sendable, Equatable, Hashable, Codable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let microsecond = PipelineTimestampUnit(rawValue: "microsecond")
    public static let millisecond = PipelineTimestampUnit(rawValue: "millisecond")
    public static let second = PipelineTimestampUnit(rawValue: "second")
    public static let minute = PipelineTimestampUnit(rawValue: "minute")
    public static let hour = PipelineTimestampUnit(rawValue: "hour")
    public static let day = PipelineTimestampUnit(rawValue: "day")
}
