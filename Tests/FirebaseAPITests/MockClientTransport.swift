//
//  MockClientTransport.swift
//
//
//  Created for testing purposes
//

import Foundation
import GRPCCore

/// Mock ClientTransport for testing
struct MockClientTransport: ClientTransport {
    typealias Bytes = [UInt8]

    var retryThrottle: RetryThrottle? {
        return nil
    }

    func connect() async throws {
        // No-op for mock - tests don't actually connect
    }

    func withStream<T: Sendable>(
        descriptor: MethodDescriptor,
        options: CallOptions,
        _ closure: (RPCStream<Inbound, Outbound>, ClientContext) async throws -> T
    ) async throws -> T {
        // Mock implementation - throw unimplemented error for testing
        throw RPCError(code: .unimplemented, message: "MockClientTransport is for testing only")
    }

    func config(forMethod descriptor: MethodDescriptor) -> MethodConfig? {
        return nil
    }

    func beginGracefulShutdown() {
        // No-op for mock
    }
}
