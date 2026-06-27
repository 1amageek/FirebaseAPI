//
//  FirestoreError.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

public enum FirestoreError: Error {
    case rpcError(FirestoreRemoteError)
    case maxAttemptsReached
    case transactionFailed(error: Error)
    case readAfterWriteError
    case minNumberOfArgumentsError
    case noResult
    case commitFailed
    case readOnlyTransactionWrite
    case invalidAccessToken(String)
    case timeout(String)
    case invalidConfiguration(String)
    case invalidPath(String)
    case invalidFieldPath(String)
    case invalidFieldValue(String)
    case invalidQuery(String)
    case invalidOperation(String)
    case unboundReference(String)
    case databaseMismatch(expected: String, actual: String)
}

extension FirestoreError {
    public var remoteErrorCode: FirestoreErrorCode? {
        switch self {
        case .rpcError(let error):
            return error.code
        case .transactionFailed(let error):
            return (error as? FirestoreError)?.remoteErrorCode
        default:
            return nil
        }
    }

    public var isRetryableRemoteError: Bool {
        remoteErrorCode?.isRetryableByDefault == true
    }
}

public enum FirestoreErrorCode: Int, Sendable {
    case cancelled = 1
    case unknown = 2
    case invalidArgument = 3
    case deadlineExceeded = 4
    case notFound = 5
    case alreadyExists = 6
    case permissionDenied = 7
    case resourceExhausted = 8
    case failedPrecondition = 9
    case aborted = 10
    case outOfRange = 11
    case unimplemented = 12
    case internalError = 13
    case unavailable = 14
    case dataLoss = 15
    case unauthenticated = 16

    public var isRetryableByDefault: Bool {
        switch self {
        case .deadlineExceeded, .resourceExhausted, .unavailable:
            return true
        default:
            return false
        }
    }
}

public struct FirestoreRemoteError: Error, Equatable, Sendable {
    public let code: FirestoreErrorCode
    public let message: String

    public init(code: FirestoreErrorCode, message: String) {
        self.code = code
        self.message = message
    }
}
