extension PipelineValue {
    public static func and(_ expressions: [PipelineValue]) -> PipelineValue {
        .function("and", expressions)
    }

    public static func or(_ expressions: [PipelineValue]) -> PipelineValue {
        .function("or", expressions)
    }

    public static func xor(_ expressions: [PipelineValue]) -> PipelineValue {
        .function("xor", expressions)
    }

    public static func nor(_ expressions: [PipelineValue]) -> PipelineValue {
        .function("nor", expressions)
    }

    public static func conditional(
        condition: PipelineValue,
        then trueValue: PipelineValue,
        else falseValue: PipelineValue
    ) -> PipelineValue {
        .function("conditional", [condition, trueValue, falseValue])
    }

    public static func switchOn(
        _ cases: [PipelineSwitchCase],
        default defaultValue: PipelineValue? = nil
    ) -> PipelineValue {
        var arguments = cases.flatMap { [$0.condition, $0.result] }
        if let defaultValue {
            arguments.append(defaultValue)
        }
        return .function("switch_on", arguments)
    }

    public static func maximum(_ values: [PipelineValue]) -> PipelineValue {
        .function("maximum", values)
    }

    public static func minimum(_ values: [PipelineValue]) -> PipelineValue {
        .function("minimum", values)
    }

    public func not() -> PipelineValue {
        .function("not", [self])
    }

    public func ifNull(_ fallback: PipelineValue) -> PipelineValue {
        .function("if_null", [self, fallback])
    }

    public func exists() -> PipelineValue {
        .function("exists", [self])
    }

    public func isAbsent() -> PipelineValue {
        .function("is_absent", [self])
    }

    public func ifAbsent(_ replacement: PipelineValue) -> PipelineValue {
        .function("if_absent", [self, replacement])
    }

    public func isError() -> PipelineValue {
        .function("is_error", [self])
    }

    public func ifError(_ catchValue: PipelineValue) -> PipelineValue {
        .function("if_error", [self, catchValue])
    }

    public static func error(_ message: PipelineValue) -> PipelineValue {
        .function("error", [message])
    }

    public static func error(_ message: String) -> PipelineValue {
        error(.string(message))
    }

    public func equalAny(_ values: [PipelineValue]) -> PipelineValue {
        .function("equal_any", [self, .array(values)])
    }

    public func notEqualAny(_ values: [PipelineValue]) -> PipelineValue {
        .function("not_equal_any", [self, .array(values)])
    }
}

public func && (lhs: PipelineValue, rhs: PipelineValue) -> PipelineValue {
    .and([lhs, rhs])
}

public func || (lhs: PipelineValue, rhs: PipelineValue) -> PipelineValue {
    .or([lhs, rhs])
}

public func ^ (lhs: PipelineValue, rhs: PipelineValue) -> PipelineValue {
    .xor([lhs, rhs])
}

public prefix func ! (expression: PipelineValue) -> PipelineValue {
    expression.not()
}
