import FirestoreCore

extension PipelineValue {
    public func typeName() -> PipelineValue {
        .function("type", [self])
    }

    public func isType(_ type: PipelineValue) -> PipelineValue {
        .function("is_type", [self, type])
    }

    public func isType(_ type: String) -> PipelineValue {
        isType(.string(type))
    }

    public func collectionID() -> PipelineValue {
        .function("collection_id", [self])
    }

    public func documentID() -> PipelineValue {
        .function("document_id", [self])
    }

    public func parentReference() -> PipelineValue {
        .function("parent", [self])
    }

    public func referenceSlice(offset: Int, length: Int) -> PipelineValue {
        referenceSlice(offset: .int(Int64(offset)), length: .int(Int64(length)))
    }

    public func referenceSlice(offset: PipelineValue, length: PipelineValue) -> PipelineValue {
        .function("reference_slice", [self, offset, length])
    }

    public func cosineDistance(_ vector: FirestoreVector) -> PipelineValue {
        cosineDistance(.vector(vector))
    }

    public func cosineDistance(_ vector: PipelineValue) -> PipelineValue {
        .function("cosine_distance", [self, vector])
    }

    public func dotProduct(_ vector: FirestoreVector) -> PipelineValue {
        dotProduct(.vector(vector))
    }

    public func dotProduct(_ vector: PipelineValue) -> PipelineValue {
        .function("dot_product", [self, vector])
    }

    public func euclideanDistance(_ vector: FirestoreVector) -> PipelineValue {
        euclideanDistance(.vector(vector))
    }

    public func euclideanDistance(_ vector: PipelineValue) -> PipelineValue {
        .function("euclidean_distance", [self, vector])
    }

    public func manhattanDistance(_ vector: FirestoreVector) -> PipelineValue {
        manhattanDistance(.vector(vector))
    }

    public func manhattanDistance(_ vector: PipelineValue) -> PipelineValue {
        .function("manhattan_distance", [self, vector])
    }

    public func vectorLength() -> PipelineValue {
        .function("vector_length", [self])
    }

    public func logicalMaximum(_ values: [PipelineValue]) -> PipelineValue {
        .function("maximum", [self] + values)
    }

    public func logicalMinimum(_ values: [PipelineValue]) -> PipelineValue {
        .function("minimum", [self] + values)
    }

    public func ascending() -> PipelineValue {
        .function("ascending", [self])
    }

    public func descending() -> PipelineValue {
        .function("descending", [self])
    }

    public static func countAll() -> PipelineValue {
        .function("count")
    }

    public func count() -> PipelineValue {
        .function("count", [self])
    }

    public static func countIf(_ expression: PipelineValue) -> PipelineValue {
        .function("count_if", [expression])
    }

    public func countIf() -> PipelineValue {
        .function("count_if", [self])
    }

    public func countDistinct() -> PipelineValue {
        .function("count_distinct", [self])
    }

    public func sum() -> PipelineValue {
        .function("sum", [self])
    }

    public func average() -> PipelineValue {
        .function("average", [self])
    }

    public func minimum() -> PipelineValue {
        .function("minimum", [self])
    }

    public func maximum() -> PipelineValue {
        .function("maximum", [self])
    }

    public func first() -> PipelineValue {
        .function("first", [self])
    }

    public func last() -> PipelineValue {
        .function("last", [self])
    }

    public func arrayAgg() -> PipelineValue {
        .function("array_agg", [self])
    }

    public func arrayAggDistinct() -> PipelineValue {
        .function("array_agg_distinct", [self])
    }
}
