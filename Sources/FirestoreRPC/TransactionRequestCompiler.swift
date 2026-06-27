import Foundation
import FirestoreCore
import FirestoreProtobuf
import SwiftProtobuf

package struct TransactionRequestCompiler {
    package let database: Database

    package init(database: Database) {
        self.database = database
    }

    package func makeBeginTransactionRequest(
        readOnly: Bool,
        readTime: Timestamp?,
        retryTransactionID: Data? = nil
    ) -> Google_Firestore_V1_BeginTransactionRequest {
        Google_Firestore_V1_BeginTransactionRequest.with {
            $0.database = database.database
            if readOnly {
                $0.options.readOnly = makeReadOnlyOptions(readTime: readTime)
            } else {
                $0.options.readWrite = makeReadWriteOptions(retryTransactionID: retryTransactionID)
            }
        }
    }

    package func makeRollbackRequest(
        transactionID: Data
    ) -> Google_Firestore_V1_RollbackRequest {
        Google_Firestore_V1_RollbackRequest.with {
            $0.database = database.database
            $0.transaction = transactionID
        }
    }

    private func makeReadOnlyOptions(
        readTime: Timestamp?
    ) -> Google_Firestore_V1_TransactionOptions.ReadOnly {
        Google_Firestore_V1_TransactionOptions.ReadOnly.with {
            guard let readTime else {
                return
            }
            $0.readTime = Google_Protobuf_Timestamp.with {
                $0.seconds = readTime.seconds
                $0.nanos = readTime.nanos
            }
        }
    }

    private func makeReadWriteOptions(
        retryTransactionID: Data?
    ) -> Google_Firestore_V1_TransactionOptions.ReadWrite {
        Google_Firestore_V1_TransactionOptions.ReadWrite.with {
            if let retryTransactionID {
                $0.retryTransaction = retryTransactionID
            }
            $0.concurrencyMode = .optimistic
        }
    }
}
