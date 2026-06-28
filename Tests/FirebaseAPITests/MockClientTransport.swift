//
//  MockClientTransport.swift
//
//
//  Created for testing purposes
//

import Foundation
import FirestoreAdminGRPCBootstrap
import FirestoreAuth
import FirestoreGRPCTransport
import FirestoreRuntimeConfig
import GRPCCore
@testable import FirestoreAPI
@testable import FirestoreAdmin

/// Mock ClientTransport for testing
struct MockClientTransport: ClientTransport {
    typealias Bytes = [UInt8]

    private let state = MockClientTransportState()

    var retryThrottle: RetryThrottle? {
        return nil
    }

    func connect() async throws {
        while await !state.isShuttingDown {
            try await Task.sleep(for: .milliseconds(10))
        }
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
        Task {
            await state.beginShutdown()
        }
    }
}

private actor MockClientTransportState {
    private var shuttingDown = false

    var isShuttingDown: Bool {
        shuttingDown
    }

    func beginShutdown() {
        shuttingDown = true
    }
}
