extension PipelineValue {
    public static func arrayExpression(_ values: [PipelineValue]) -> PipelineValue {
        .function("array", values)
    }

    public static func concat(_ values: [PipelineValue]) -> PipelineValue {
        .function("concat", values)
    }

    public func concat(_ values: [PipelineValue]) -> PipelineValue {
        .function("concat", [self] + values)
    }

    public func length() -> PipelineValue {
        .function("length", [self])
    }

    public func genericReverse() -> PipelineValue {
        .function("reverse", [self])
    }

    public func arrayConcat(_ arrays: [PipelineValue]) -> PipelineValue {
        .function("array_concat", [self] + arrays)
    }

    public func arrayContains(_ value: PipelineValue) -> PipelineValue {
        .function("array_contains", [self, value])
    }

    public func arrayContainsAll(_ values: [PipelineValue]) -> PipelineValue {
        .function("array_contains_all", [self, .array(values)])
    }

    public func arrayContainsAny(_ values: [PipelineValue]) -> PipelineValue {
        .function("array_contains_any", [self, .array(values)])
    }

    public func arrayFilter(
        parameter: String = "element",
        _ predicate: (PipelineValue) -> PipelineValue
    ) -> PipelineValue {
        let variable = PipelineValue.variable(parameter)
        return arrayFilter(.lambda(parameters: [parameter], body: predicate(variable)))
    }

    public func arrayFilter(_ predicate: PipelineValue) -> PipelineValue {
        .function("array_filter", [self, predicate])
    }

    public func arrayFirst() -> PipelineValue {
        .function("array_first", [self])
    }

    public func arrayFirst(_ count: Int) -> PipelineValue {
        arrayFirst(.int(Int64(count)))
    }

    public func arrayFirst(_ count: PipelineValue) -> PipelineValue {
        .function("array_first_n", [self, count])
    }

    public func arrayGet(_ index: Int) -> PipelineValue {
        arrayGet(.int(Int64(index)))
    }

    public func arrayGet(_ index: PipelineValue) -> PipelineValue {
        .function("array_get", [self, index])
    }

    public func arrayIndex(of value: PipelineValue) -> PipelineValue {
        .function("array_index_of", [self, value])
    }

    public func arrayIndexes(of value: PipelineValue) -> PipelineValue {
        .function("array_index_of_all", [self, value])
    }

    public func arrayLength() -> PipelineValue {
        .function("array_length", [self])
    }

    public func arrayLast() -> PipelineValue {
        .function("array_last", [self])
    }

    public func arrayLast(_ count: Int) -> PipelineValue {
        arrayLast(.int(Int64(count)))
    }

    public func arrayLast(_ count: PipelineValue) -> PipelineValue {
        .function("array_last_n", [self, count])
    }

    public func arrayReverse() -> PipelineValue {
        .function("array_reverse", [self])
    }

    public func arraySlice(start: Int, end: Int? = nil) -> PipelineValue {
        arraySlice(
            start: .int(Int64(start)),
            end: end.map { .int(Int64($0)) }
        )
    }

    public func arraySlice(start: PipelineValue, end: PipelineValue? = nil) -> PipelineValue {
        var arguments: [PipelineValue] = [self, start]
        if let end {
            arguments.append(end)
        }
        return .function("array_slice", arguments)
    }

    public func arrayTransform(
        parameter: String = "element",
        _ expression: (PipelineValue) -> PipelineValue
    ) -> PipelineValue {
        let variable = PipelineValue.variable(parameter)
        return arrayTransform(.lambda(parameters: [parameter], body: expression(variable)))
    }

    public func arrayTransform(
        element: String = "element",
        index: String = "index",
        _ expression: (PipelineValue, PipelineValue) -> PipelineValue
    ) -> PipelineValue {
        let elementVariable = PipelineValue.variable(element)
        let indexVariable = PipelineValue.variable(index)
        return arrayTransform(.lambda(parameters: [element, index], body: expression(elementVariable, indexVariable)))
    }

    public func arrayTransform(_ expression: PipelineValue) -> PipelineValue {
        .function("array_transform", [self, expression])
    }

    public func maximum(_ count: Int) -> PipelineValue {
        maximum(.int(Int64(count)))
    }

    public func maximum(_ count: PipelineValue) -> PipelineValue {
        .function("maximum_n", [self, count])
    }

    public func minimum(_ count: Int) -> PipelineValue {
        minimum(.int(Int64(count)))
    }

    public func minimum(_ count: PipelineValue) -> PipelineValue {
        .function("minimum_n", [self, count])
    }

    public func join(delimiter: PipelineValue, nullText: PipelineValue? = nil) -> PipelineValue {
        var arguments: [PipelineValue] = [self, delimiter]
        if let nullText {
            arguments.append(nullText)
        }
        return .function("join", arguments)
    }

    public func join(delimiter: String, nullText: String? = nil) -> PipelineValue {
        join(
            delimiter: .string(delimiter),
            nullText: nullText.map(PipelineValue.string)
        )
    }

    public static func mapExpression(_ entries: [(String, PipelineValue)]) -> PipelineValue {
        .function("map", entries.flatMap { [.string($0.0), $0.1] })
    }

    public static func mapExpression(_ entries: [String: PipelineValue]) -> PipelineValue {
        let sortedEntries = entries.sorted { $0.key < $1.key }
        return mapExpression(sortedEntries.map { ($0.key, $0.value) })
    }

    public func mapGet(_ key: String) -> PipelineValue {
        .function("map_get", [self, .string(key)])
    }

    public func mapSet(_ entries: [(String, PipelineValue)]) -> PipelineValue {
        .function("map_set", [self] + entries.flatMap { [.string($0.0), $0.1] })
    }

    public func mapSet(_ entries: [String: PipelineValue]) -> PipelineValue {
        let sortedEntries = entries.sorted { $0.key < $1.key }
        return mapSet(sortedEntries.map { ($0.key, $0.value) })
    }

    public func mapRemove(_ keys: [String]) -> PipelineValue {
        .function("map_remove", [self] + keys.map(PipelineValue.string))
    }

    public static func mapMerge(_ maps: [PipelineValue]) -> PipelineValue {
        .function("map_merge", maps)
    }

    public func mapMerge(_ maps: [PipelineValue]) -> PipelineValue {
        .function("map_merge", [self] + maps)
    }

    public static func currentContext() -> PipelineValue {
        .function("current_context")
    }

    public func mapKeys() -> PipelineValue {
        .function("map_keys", [self])
    }

    public func mapValues() -> PipelineValue {
        .function("map_values", [self])
    }

    public func mapEntries() -> PipelineValue {
        .function("map_entries", [self])
    }
}
