import Foundation

package struct WriteData {
    package var documentReference: DocumentReference
    package var data: [String: Any]?
    package var merge: Bool
    package var mergeFields: [String]?
    package var exist: Bool?

    package init(
        documentReference: DocumentReference,
        data: [String: Any]?,
        merge: Bool,
        mergeFields: [String]? = nil,
        exist: Bool? = nil
    ) {
        self.documentReference = documentReference
        self.data = data
        self.merge = merge
        self.mergeFields = mergeFields
        self.exist = exist
    }
}
