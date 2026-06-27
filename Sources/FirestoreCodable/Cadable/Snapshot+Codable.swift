import Foundation
import FirestoreCore

extension DocumentSnapshot {
    public func data<T: Decodable>(as type: T.Type) throws -> T? {
        guard let data = data() else {
            return nil
        }
        return try FirestoreDecoder().decode(type, from: data, in: documentReference)
    }
}

extension QueryDocumentSnapshot {
    public func data<T: Decodable>(as type: T.Type) throws -> T {
        try FirestoreDecoder().decode(type, from: data(), in: documentReference)
    }
}

extension QuerySnapshot {
    public func documents<T: Decodable>(as type: T.Type) throws -> [T] {
        try documents.map { try $0.data(as: type) }
    }
}
