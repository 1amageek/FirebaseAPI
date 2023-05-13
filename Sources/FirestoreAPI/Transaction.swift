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

    private var transactionID: Data?

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
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let querySnapshot = try await query.getDocuments(firestore: firestore, headers: headers)
        return querySnapshot
    }

    func getAll(documentReferences: DocumentReference...) async throws -> [DocumentSnapshot] {
        guard writeBatch.writes.isEmpty else {
            throw FirestoreError.readAfterWriteError
        }
        guard !documentReferences.isEmpty else {
            throw FirestoreError.minNumberOfArgumentsError
        }
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AccessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        return try await firestore.batchGetDocuments(documentReferences: documentReferences, transactionID: transactionID, headers: headers)
    }

    func create(documentReference: DocumentReference, data: [String: Any]) async throws {
        writeBatch.create(data: data, forDocument: documentReference)
    }

    func set(documentReference: DocumentReference, data: [String: Any]) async throws {
        writeBatch.setData(data: data, forDocument: documentReference)
    }

    func update(documentReference: DocumentReference, data: [String: Any]) async throws {
        writeBatch.updateData(fields: data, forDocument: documentReference)
    }

    func delete(documentReference: DocumentReference) async throws {
        writeBatch.deleteDocument(document: documentReference)
    }

    func begin(readOnly: Bool, readTime: Timestamp?) async throws {
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let beginTransactionResponse = try await firestore.beginTransaction(readOnly: readOnly, readTime: readTime, headers: headers)
        transactionID = beginTransactionResponse.transaction
    }

    func commit() async throws {
        guard let transactionID = transactionID else {
            throw TransactionError.missingTransactionID
        }
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        let commitResponse = try await firestore.commitTransaction(transactionID: transactionID, writeBatch: writeBatch, headers: headers)
        if !commitResponse.hasCommitTime {
            throw TransactionError.commitFailed
        }
    }

    func rollback() async throws {
        guard let transactionID = transactionID else {
            throw TransactionError.missingTransactionID
        }
        guard let accessToken = try await firestore.getAccessToken() else {
            fatalError("AcessToken is empty")
        }
        let headers = HPACKHeaders([("authorization", "Bearer \(accessToken)")])
        _ = try await firestore.rollbackTransaction(transactionID: transactionID, headers: headers)
    }
}
