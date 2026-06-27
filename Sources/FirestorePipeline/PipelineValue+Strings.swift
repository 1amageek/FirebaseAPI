extension PipelineValue {
    public func byteLength() -> PipelineValue {
        .function("byte_length", [self])
    }

    public func charLength() -> PipelineValue {
        .function("char_length", [self])
    }

    public func startsWith(_ prefix: PipelineValue) -> PipelineValue {
        .function("starts_with", [self, prefix])
    }

    public func startsWith(_ prefix: String) -> PipelineValue {
        startsWith(.string(prefix))
    }

    public func endsWith(_ postfix: PipelineValue) -> PipelineValue {
        .function("ends_with", [self, postfix])
    }

    public func endsWith(_ postfix: String) -> PipelineValue {
        endsWith(.string(postfix))
    }

    public func like(_ pattern: PipelineValue) -> PipelineValue {
        .function("like", [self, pattern])
    }

    public func like(_ pattern: String) -> PipelineValue {
        like(.string(pattern))
    }

    public func regexContains(_ pattern: PipelineValue) -> PipelineValue {
        .function("regex_contains", [self, pattern])
    }

    public func regexContains(_ pattern: String) -> PipelineValue {
        regexContains(.string(pattern))
    }

    public func regexMatch(_ pattern: PipelineValue) -> PipelineValue {
        .function("regex_match", [self, pattern])
    }

    public func regexMatch(_ pattern: String) -> PipelineValue {
        regexMatch(.string(pattern))
    }

    public static func stringConcat(_ values: [PipelineValue]) -> PipelineValue {
        .function("string_concat", values)
    }

    public func stringConcat(_ values: [PipelineValue]) -> PipelineValue {
        .function("string_concat", [self] + values)
    }

    public func stringConcat(_ value: String) -> PipelineValue {
        stringConcat([.string(value)])
    }

    public func stringContains(_ substring: PipelineValue) -> PipelineValue {
        .function("string_contains", [self, substring])
    }

    public func stringContains(_ substring: String) -> PipelineValue {
        stringContains(.string(substring))
    }

    public func stringIndexOf(_ search: PipelineValue) -> PipelineValue {
        .function("string_index_of", [self, search])
    }

    public func stringIndexOf(_ search: String) -> PipelineValue {
        stringIndexOf(.string(search))
    }

    public func toUpper() -> PipelineValue {
        .function("to_upper", [self])
    }

    public func toLower() -> PipelineValue {
        .function("to_lower", [self])
    }

    public func substring(position: Int, length: Int? = nil) -> PipelineValue {
        var arguments: [PipelineValue] = [self, .int(Int64(position))]
        if let length {
            arguments.append(.int(Int64(length)))
        }
        return .function("substring", arguments)
    }

    public func substring(position: PipelineValue, length: PipelineValue? = nil) -> PipelineValue {
        var arguments: [PipelineValue] = [self, position]
        if let length {
            arguments.append(length)
        }
        return .function("substring", arguments)
    }

    public func reverse() -> PipelineValue {
        .function("string_reverse", [self])
    }

    public func stringRepeat(_ repetitions: Int) -> PipelineValue {
        .function("string_repeat", [self, .int(Int64(repetitions))])
    }

    public func stringRepeat(_ repetitions: PipelineValue) -> PipelineValue {
        .function("string_repeat", [self, repetitions])
    }

    public func stringReplaceAll(find: PipelineValue, replacement: PipelineValue) -> PipelineValue {
        .function("string_replace_all", [self, find, replacement])
    }

    public func stringReplaceAll(find: String, replacement: String) -> PipelineValue {
        stringReplaceAll(find: .string(find), replacement: .string(replacement))
    }

    public func stringReplaceOne(find: PipelineValue, replacement: PipelineValue) -> PipelineValue {
        .function("string_replace_one", [self, find, replacement])
    }

    public func stringReplaceOne(find: String, replacement: String) -> PipelineValue {
        stringReplaceOne(find: .string(find), replacement: .string(replacement))
    }

    public func trim(_ valuesToTrim: PipelineValue? = nil) -> PipelineValue {
        if let valuesToTrim {
            return .function("trim", [self, valuesToTrim])
        }
        return .function("trim", [self])
    }

    public func trim(_ valuesToTrim: String) -> PipelineValue {
        trim(.string(valuesToTrim))
    }

    public func leftTrim(_ valueToTrim: PipelineValue? = nil) -> PipelineValue {
        if let valueToTrim {
            return .function("ltrim", [self, valueToTrim])
        }
        return .function("ltrim", [self])
    }

    public func leftTrim(_ valueToTrim: String) -> PipelineValue {
        leftTrim(.string(valueToTrim))
    }

    public func rightTrim(_ valueToTrim: PipelineValue? = nil) -> PipelineValue {
        if let valueToTrim {
            return .function("rtrim", [self, valueToTrim])
        }
        return .function("rtrim", [self])
    }

    public func rightTrim(_ valueToTrim: String) -> PipelineValue {
        rightTrim(.string(valueToTrim))
    }

    public func split(delimiter: PipelineValue? = nil) -> PipelineValue {
        if let delimiter {
            return .function("split", [self, delimiter])
        }
        return .function("split", [self])
    }

    public func split(delimiter: String) -> PipelineValue {
        split(delimiter: .string(delimiter))
    }
}
