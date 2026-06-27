extension PipelineValue {
    public static func currentTimestamp() -> PipelineValue {
        .function("current_timestamp")
    }

    public func timestampTrunc(
        _ granularity: PipelineTimestampGranularity,
        timeZone: String? = nil
    ) -> PipelineValue {
        var arguments: [PipelineValue] = [self, .string(granularity.rawValue)]
        if let timeZone {
            arguments.append(.string(timeZone))
        }
        return .function("timestamp_trunc", arguments)
    }

    public func unixMicrosToTimestamp() -> PipelineValue {
        .function("unix_micros_to_timestamp", [self])
    }

    public static func unixMicrosToTimestamp(_ input: Int64) -> PipelineValue {
        .int(input).unixMicrosToTimestamp()
    }

    public func unixMillisToTimestamp() -> PipelineValue {
        .function("unix_millis_to_timestamp", [self])
    }

    public static func unixMillisToTimestamp(_ input: Int64) -> PipelineValue {
        .int(input).unixMillisToTimestamp()
    }

    public func unixSecondsToTimestamp() -> PipelineValue {
        .function("unix_seconds_to_timestamp", [self])
    }

    public static func unixSecondsToTimestamp(_ input: Int64) -> PipelineValue {
        .int(input).unixSecondsToTimestamp()
    }

    public func timestampAdd(_ amount: Int64, _ unit: PipelineTimestampUnit) -> PipelineValue {
        timestampAdd(.int(amount), unit)
    }

    public func timestampAdd(_ amount: Int, _ unit: PipelineTimestampUnit) -> PipelineValue {
        timestampAdd(Int64(amount), unit)
    }

    public func timestampAdd(_ amount: PipelineValue, _ unit: PipelineTimestampUnit) -> PipelineValue {
        .function("timestamp_add", [self, .string(unit.rawValue), amount])
    }

    public func timestampSubtract(_ amount: Int64, _ unit: PipelineTimestampUnit) -> PipelineValue {
        timestampSubtract(.int(amount), unit)
    }

    public func timestampSubtract(_ amount: Int, _ unit: PipelineTimestampUnit) -> PipelineValue {
        timestampSubtract(Int64(amount), unit)
    }

    public func timestampSubtract(_ amount: PipelineValue, _ unit: PipelineTimestampUnit) -> PipelineValue {
        .function("timestamp_sub", [self, .string(unit.rawValue), amount])
    }

    public func timestampToUnixMicros() -> PipelineValue {
        .function("timestamp_to_unix_micros", [self])
    }

    public func timestampToUnixMillis() -> PipelineValue {
        .function("timestamp_to_unix_millis", [self])
    }

    public func timestampToUnixSeconds() -> PipelineValue {
        .function("timestamp_to_unix_seconds", [self])
    }

    public func timestampDiff(from start: PipelineValue, unit: PipelineTimestampUnit) -> PipelineValue {
        .function("timestamp_diff", [self, start, .string(unit.rawValue)])
    }

    public func timestampExtract(
        _ part: PipelineTimestampPart,
        timeZone: String? = nil
    ) -> PipelineValue {
        var arguments: [PipelineValue] = [self, .string(part.rawValue)]
        if let timeZone {
            arguments.append(.string(timeZone))
        }
        return .function("timestamp_extract", arguments)
    }
}
