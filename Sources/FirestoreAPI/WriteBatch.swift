//
//  WriteBatch.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import GRPCCore

struct WriteData {
    var documentReference: DocumentReference
    var data: [String: Any]?
    var merge: Bool
    var mergeFields: [String]?
    var exist: Bool?
}

public class WriteBatch<Transport: ClientTransport> {

    var firestore: Firestore<Transport>

    var writes: [WriteData] = []

    init(firestore: Firestore<Transport>) {
        self.firestore = firestore
    }

    @discardableResult
    func create(data: [String: Any], forDocument document: DocumentReference) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: false, exist: false))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: false))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference, merge: Bool) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: merge))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference, mergeFields: [String]) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: true, mergeFields: mergeFields))
        return self
    }

    @discardableResult
    public func updateData(fields: [String: Any], forDocument document: DocumentReference) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: fields, merge: true, exist: true))
        return self
    }

    @discardableResult
    public func deleteDocument(document: DocumentReference) -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: nil, merge: false))
        return self
    }
}

extension WriteBatch {

    @discardableResult
    func create<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        self.create(data: documentData, forDocument: document)
        return self
    }

    @discardableResult
    public func setData<T: Encodable>(from data: T, forDocument document: DocumentReference) throws -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        self.setData(data: documentData, forDocument: document)
        return self
    }

    @discardableResult
    public func setData<T: Encodable>(from data: T, forDocument document: DocumentReference, merge: Bool) throws -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        self.setData(data: documentData, forDocument: document, merge: merge)
        return self
    }

    @discardableResult
    public func setData<T: Encodable>(from data: T, forDocument document: DocumentReference, mergeFields: [String]) throws -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        let documentData = try FirestoreEncoder().encode(data)
        self.setData(data: documentData, forDocument: document, mergeFields: mergeFields)
        return self
    }

    @discardableResult
    public func updateData<T: Encodable>(from fields: T, forDocument document: DocumentReference) throws -> WriteBatch<Transport> {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        let documentData = try FirestoreEncoder().encode(fields)
        self.updateData(fields: documentData, forDocument: document)
        return self
    }
}
