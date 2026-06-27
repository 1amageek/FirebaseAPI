import Foundation
import FirestoreCore

public struct PipelineQueryRow: Sendable {
    private let decodedFields: [String: FirestoreDocumentValue]
    public let documentReference: DocumentReference?
    public let createTime: Timestamp?
    public let updateTime: Timestamp?

    package init(
        fields: [String: FirestoreDocumentValue],
        documentReference: DocumentReference? = nil,
        createTime: Timestamp? = nil,
        updateTime: Timestamp? = nil
    ) {
        self.decodedFields = fields
        self.documentReference = documentReference
        self.createTime = createTime
        self.updateTime = updateTime
    }

    public init(
        data: [String: Any],
        documentReference: DocumentReference? = nil,
        createTime: Timestamp? = nil,
        updateTime: Timestamp? = nil
    ) throws {
        self.init(
            fields: try FirestoreDocumentValue.fields(from: data),
            documentReference: documentReference,
            createTime: createTime,
            updateTime: updateTime
        )
    }

    public var data: [String: Any] {
        decodedFields.mapValues(\.anyValue)
    }
}
