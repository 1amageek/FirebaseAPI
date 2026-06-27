import FirestoreCore
public struct PipelineTimestampPart: RawRepresentable, Sendable, Equatable, Hashable, Codable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let microsecond = PipelineTimestampPart(rawValue: "microsecond")
    public static let millisecond = PipelineTimestampPart(rawValue: "millisecond")
    public static let second = PipelineTimestampPart(rawValue: "second")
    public static let minute = PipelineTimestampPart(rawValue: "minute")
    public static let hour = PipelineTimestampPart(rawValue: "hour")
    public static let day = PipelineTimestampPart(rawValue: "day")
    public static let dayOfWeek = PipelineTimestampPart(rawValue: "dayofweek")
    public static let dayOfYear = PipelineTimestampPart(rawValue: "dayofyear")
    public static let week = PipelineTimestampPart(rawValue: "week")
    public static let month = PipelineTimestampPart(rawValue: "month")
    public static let quarter = PipelineTimestampPart(rawValue: "quarter")
    public static let year = PipelineTimestampPart(rawValue: "year")
    public static let isoWeek = PipelineTimestampPart(rawValue: "isoweek")
    public static let isoYear = PipelineTimestampPart(rawValue: "isoyear")

    public static func week(startingOn weekday: String) -> PipelineTimestampPart {
        PipelineTimestampPart(rawValue: "week(\(weekday))")
    }
}
