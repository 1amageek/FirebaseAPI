extension PipelineValue {
    public func add(_ value: PipelineValue) -> PipelineValue {
        .function("add", [self, value])
    }

    public func add(_ value: Int) -> PipelineValue {
        add(.int(Int64(value)))
    }

    public func add(_ value: Int64) -> PipelineValue {
        add(.int(value))
    }

    public func add(_ value: Double) -> PipelineValue {
        add(.double(value))
    }

    public func subtract(_ value: PipelineValue) -> PipelineValue {
        .function("subtract", [self, value])
    }

    public func subtract(_ value: Int) -> PipelineValue {
        subtract(.int(Int64(value)))
    }

    public func subtract(_ value: Int64) -> PipelineValue {
        subtract(.int(value))
    }

    public func subtract(_ value: Double) -> PipelineValue {
        subtract(.double(value))
    }

    public func multiply(_ value: PipelineValue) -> PipelineValue {
        .function("multiply", [self, value])
    }

    public func multiply(_ value: Int) -> PipelineValue {
        multiply(.int(Int64(value)))
    }

    public func multiply(_ value: Int64) -> PipelineValue {
        multiply(.int(value))
    }

    public func multiply(_ value: Double) -> PipelineValue {
        multiply(.double(value))
    }

    public func divide(_ value: PipelineValue) -> PipelineValue {
        .function("divide", [self, value])
    }

    public func divide(_ value: Int) -> PipelineValue {
        divide(.int(Int64(value)))
    }

    public func divide(_ value: Int64) -> PipelineValue {
        divide(.int(value))
    }

    public func divide(_ value: Double) -> PipelineValue {
        divide(.double(value))
    }

    public func mod(_ value: PipelineValue) -> PipelineValue {
        .function("mod", [self, value])
    }

    public func pow(_ exponent: PipelineValue) -> PipelineValue {
        .function("pow", [self, exponent])
    }

    public func pow(_ exponent: Int) -> PipelineValue {
        pow(.int(Int64(exponent)))
    }

    public func pow(_ exponent: Int64) -> PipelineValue {
        pow(.int(exponent))
    }

    public func pow(_ exponent: Double) -> PipelineValue {
        pow(.double(exponent))
    }

    public func abs() -> PipelineValue {
        .function("abs", [self])
    }

    public func ceil() -> PipelineValue {
        .function("ceil", [self])
    }

    public func floor() -> PipelineValue {
        .function("floor", [self])
    }

    public func round(places: Int? = nil) -> PipelineValue {
        if let places {
            return round(places: .int(Int64(places)))
        }
        return .function("round", [self])
    }

    public func round(places: PipelineValue) -> PipelineValue {
        .function("round", [self, places])
    }

    public func trunc(places: Int? = nil) -> PipelineValue {
        if let places {
            return trunc(places: .int(Int64(places)))
        }
        return .function("trunc", [self])
    }

    public func trunc(places: PipelineValue) -> PipelineValue {
        .function("trunc", [self, places])
    }

    public func sqrt() -> PipelineValue {
        .function("sqrt", [self])
    }

    public func exp() -> PipelineValue {
        .function("exp", [self])
    }

    public func ln() -> PipelineValue {
        .function("ln", [self])
    }

    public func log(base: PipelineValue) -> PipelineValue {
        .function("log", [self, base])
    }

    public func log(base: Int) -> PipelineValue {
        log(base: .int(Int64(base)))
    }

    public func log(base: Int64) -> PipelineValue {
        log(base: .int(base))
    }

    public func log(base: Double) -> PipelineValue {
        log(base: .double(base))
    }

    public func log10() -> PipelineValue {
        .function("log10", [self])
    }

    public func equal(_ value: PipelineValue) -> PipelineValue {
        .function("equal", [self, value])
    }

    public func equal(_ value: String) -> PipelineValue {
        equal(.string(value))
    }

    public func equal(_ value: Int) -> PipelineValue {
        equal(.int(Int64(value)))
    }

    public func equal(_ value: Int64) -> PipelineValue {
        equal(.int(value))
    }

    public func equal(_ value: Double) -> PipelineValue {
        equal(.double(value))
    }

    public func equal(_ value: Bool) -> PipelineValue {
        equal(.bool(value))
    }

    public func notEqual(_ value: PipelineValue) -> PipelineValue {
        .function("not_equal", [self, value])
    }

    public func notEqual(_ value: String) -> PipelineValue {
        notEqual(.string(value))
    }

    public func notEqual(_ value: Int) -> PipelineValue {
        notEqual(.int(Int64(value)))
    }

    public func notEqual(_ value: Int64) -> PipelineValue {
        notEqual(.int(value))
    }

    public func notEqual(_ value: Double) -> PipelineValue {
        notEqual(.double(value))
    }

    public func notEqual(_ value: Bool) -> PipelineValue {
        notEqual(.bool(value))
    }

    public func lessThan(_ value: PipelineValue) -> PipelineValue {
        .function("less_than", [self, value])
    }

    public func lessThan(_ value: Int) -> PipelineValue {
        lessThan(.int(Int64(value)))
    }

    public func lessThan(_ value: Int64) -> PipelineValue {
        lessThan(.int(value))
    }

    public func lessThan(_ value: Double) -> PipelineValue {
        lessThan(.double(value))
    }

    public func lessThanOrEqual(_ value: PipelineValue) -> PipelineValue {
        .function("less_than_or_equal", [self, value])
    }

    public func lessThanOrEqual(_ value: Int) -> PipelineValue {
        lessThanOrEqual(.int(Int64(value)))
    }

    public func lessThanOrEqual(_ value: Int64) -> PipelineValue {
        lessThanOrEqual(.int(value))
    }

    public func lessThanOrEqual(_ value: Double) -> PipelineValue {
        lessThanOrEqual(.double(value))
    }

    public func greaterThan(_ value: PipelineValue) -> PipelineValue {
        .function("greater_than", [self, value])
    }

    public func greaterThan(_ value: Int) -> PipelineValue {
        greaterThan(.int(Int64(value)))
    }

    public func greaterThan(_ value: Int64) -> PipelineValue {
        greaterThan(.int(value))
    }

    public func greaterThan(_ value: Double) -> PipelineValue {
        greaterThan(.double(value))
    }

    public func greaterThanOrEqual(_ value: PipelineValue) -> PipelineValue {
        .function("greater_than_or_equal", [self, value])
    }

    public func greaterThanOrEqual(_ value: Int) -> PipelineValue {
        greaterThanOrEqual(.int(Int64(value)))
    }

    public func greaterThanOrEqual(_ value: Int64) -> PipelineValue {
        greaterThanOrEqual(.int(value))
    }

    public func greaterThanOrEqual(_ value: Double) -> PipelineValue {
        greaterThanOrEqual(.double(value))
    }

    public func cmp(_ value: PipelineValue) -> PipelineValue {
        .function("cmp", [self, value])
    }
}
