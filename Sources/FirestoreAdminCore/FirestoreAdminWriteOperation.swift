import Foundation
import FirestoreCore

/// A buffered Admin write summary exposed to custom clients and test doubles.
public struct FirestoreAdminWriteOperation {
    public enum Kind: Equatable {
        case create
        case set
        case update
        case delete
    }

    public let kind: Kind
    public let document: DocumentReference
    public let data: [String: Any]?
    public let merge: Bool
    public let mergeFields: [String]?

    package init(write: WriteData) {
        self.kind = Self.kind(for: write)
        self.document = write.documentReference
        self.data = write.data
        self.merge = write.merge
        self.mergeFields = write.mergeFields
    }

    private static func kind(for write: WriteData) -> Kind {
        guard write.data != nil else {
            return .delete
        }
        if write.exist == false {
            return .create
        }
        if write.exist == true {
            return .update
        }
        return .set
    }
}
