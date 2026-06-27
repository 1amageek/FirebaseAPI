import Foundation
import FirestoreCore
import GRPCCore

extension FirestoreError {
    static func fromRPCError(_ error: RPCError) -> FirestoreError {
        .rpcError(FirestoreRemoteError(code: FirestoreErrorCode(error.code), message: error.message))
    }
}

extension FirestoreErrorCode {
    init(_ code: RPCError.Code) {
        switch code {
        case .cancelled:
            self = .cancelled
        case .unknown:
            self = .unknown
        case .invalidArgument:
            self = .invalidArgument
        case .deadlineExceeded:
            self = .deadlineExceeded
        case .notFound:
            self = .notFound
        case .alreadyExists:
            self = .alreadyExists
        case .permissionDenied:
            self = .permissionDenied
        case .resourceExhausted:
            self = .resourceExhausted
        case .failedPrecondition:
            self = .failedPrecondition
        case .aborted:
            self = .aborted
        case .outOfRange:
            self = .outOfRange
        case .unimplemented:
            self = .unimplemented
        case .internalError:
            self = .internalError
        case .unavailable:
            self = .unavailable
        case .dataLoss:
            self = .dataLoss
        case .unauthenticated:
            self = .unauthenticated
        default:
            self = .unknown
        }
    }
}
