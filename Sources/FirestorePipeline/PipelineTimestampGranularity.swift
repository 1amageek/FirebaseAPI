import FirestoreCore
public struct PipelineTimestampGranularity: RawRepresentable, Sendable, Equatable, Hashable, Codable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let microsecond = PipelineTimestampGranularity(rawValue: "microsecond")
    public static let millisecond = PipelineTimestampGranularity(rawValue: "millisecond")
    public static let second = PipelineTimestampGranularity(rawValue: "second")
    public static let minute = PipelineTimestampGranularity(rawValue: "minute")
    public static let hour = PipelineTimestampGranularity(rawValue: "hour")
    public static let day = PipelineTimestampGranularity(rawValue: "day")
    public static let week = PipelineTimestampGranularity(rawValue: "week")
    public static let month = PipelineTimestampGranularity(rawValue: "month")
    public static let quarter = PipelineTimestampGranularity(rawValue: "quarter")
    public static let year = PipelineTimestampGranularity(rawValue: "year")
    public static let isoYear = PipelineTimestampGranularity(rawValue: "isoyear")

    public static func week(startingOn weekday: String) -> PipelineTimestampGranularity {
        PipelineTimestampGranularity(rawValue: "week(\(weekday))")
    }
}
