//
//  FirestoreError.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation
import GRPC

public enum FirestoreError: Error {
    case serverError(GRPCStatus)
    case maxAttemptsReached
    case transactionFailed(error: Error)
    case readAfterWriteError
    case minNumberOfArgumentsError
    case noResult
    case invalidAccessToken(String)
    case timeout(String)
    case invalidConfiguration(String)
}
