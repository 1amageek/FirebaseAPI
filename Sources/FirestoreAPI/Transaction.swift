//
//  Transaction.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import GRPC
import NIO
import SwiftProtobuf
import NIOHPACK

public struct TransactionOptions {
    var maxAttempts: Int
    var readOnly: Bool
    var readTime: Timestamp?

    public init(maxAttempts: Int = 5, readOnly: Bool = false, readTime: Timestamp? = nil) {
        self.maxAttempts = maxAttempts
        self.readOnly = readOnly
        self.readTime = readTime
    }
}

enum TransactionError: Error {
    case missingTransactionID
    case commitFailed
    case rollbackFailed
}

public class Transaction {

    private var firestore: Firestore

    private var writeBatch: WriteBatch

    private var requestTag: String

    private var id: Data?

    var backoff: ExponentialBackoff

    var options: TransactionOptions

    init(firestore: Firestore, options: TransactionOptions = TransactionOptions(maxAttempts: 5, readOnly: false)) {
        self.firestore = firestore
        self.requestTag = UUID().uuidString
        self.writeBatch = WriteBatch(firestore: firestore)
        self.options = options
        self.backoff = ExponentialBackoff(maxAttempts: options.maxAttempts)
    }

    public func get(documentReference: DocumentReference) async throws -> DocumentSnapshot {
        return try await getAll(documentReferences: documentReference).first!
    }

    public func get(query: Query) async throws -> QuerySnapshot {
        return try await firestore.runQuery(query: query.makeQuery(), transactionID: id)
    }

    public func getAll(documentReferences: DocumentReference...) async throws -> [DocumentSnapshot] {
        guard writeBatch.writes.isEmpty else {
            throw FirestoreError.readAfterWriteError
        }
        guard !documentReferences.isEmpty else {
            throw FirestoreError.minNumberOfArgumentsError
        }
        return try await firestore.batchGetDocuments(documentReferences: documentReferences, transactionID: id)
    }

    public func create(documentReference: DocumentReference, data: [String: Any]) {
        writeBatch.create(data: data, forDocument: documentReference)
    }

    public func set(documentReference: DocumentReference, data: [String: Any]) {
        writeBatch.setData(data: data, forDocument: documentReference)
    }

    public func update(documentReference: DocumentReference, data: [String: Any]) {
        writeBatch.updateData(fields: data, forDocument: documentReference)
    }

    public func delete(documentReference: DocumentReference) {
        writeBatch.deleteDocument(document: documentReference)
    }

    func begin(readOnly: Bool, readTime: Timestamp?) async throws {
        let beginTransactionResponse = try await firestore.beginTransaction(readOnly: readOnly, readTime: readTime)
        id = beginTransactionResponse.transaction
        writeBatch = firestore.batch()
    }

    func commit() async throws {
        guard let id else {
            throw TransactionError.missingTransactionID
        }
        let commitResponse = try await firestore.commitTransaction(transactionID: id, writeBatch: writeBatch)
        if !commitResponse.hasCommitTime {
            throw TransactionError.commitFailed
        }
    }

    func rollback() async throws {
        guard let id else {
            throw TransactionError.missingTransactionID
        }
        _ = try await firestore.rollbackTransaction(transactionID: id)
    }
}
