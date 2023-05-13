//
//  WriteBatch.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation

struct WriteData {
    var documentReference: DocumentReference
    var data: [String: Any]?
    var merge: Bool
    var mergeFields: [String]?
    var exist: Bool?
}

public class WriteBatch {

    var firestore: Firestore

    var writes: [WriteData] = []

    init(firestore: Firestore) {
        self.firestore = firestore
    }

    @discardableResult
    func create(data: [String: Any], forDocument document: DocumentReference) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: false, exist: false))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: false))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference, merge: Bool) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: merge))
        return self
    }

    @discardableResult
    public func setData(data: [String: Any], forDocument document: DocumentReference, mergeFields: [String]) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: data, merge: true, mergeFields: mergeFields))
        return self
    }

    @discardableResult
    public func updateData(fields: [String: Any], forDocument document: DocumentReference) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: fields, merge: true, exist: true))
        return self
    }

    @discardableResult
    public func deleteDocument(document: DocumentReference) -> WriteBatch {
        guard document.database == firestore.database else {
            print("Invalid project ID")
            return self
        }
        writes.append(.init(documentReference: document, data: [:], merge: false))
        return self
    }
}
