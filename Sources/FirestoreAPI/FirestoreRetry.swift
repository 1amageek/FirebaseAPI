//
//  FirestoreRetry.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import GRPCCore

public protocol FirestoreRetryable: Sendable {
    associatedtype Output
    func execute() async throws -> Output
}

public struct FirestoreRetryContext {
    public let attempt: Int
    public let error: Error
    public let startTime: Date
    public let strategy: FirestoreRetryStrategy
    
    public var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

public actor FirestoreRetryHandler {
    private let strategy: FirestoreRetryStrategy
    private let maxAttempts: Int
    private let maxDuration: TimeInterval?
    
    public init(
        strategy: FirestoreRetryStrategy,
        maxAttempts: Int = 5,
        maxDuration: TimeInterval? = nil
    ) {
        self.strategy = strategy
        self.maxAttempts = maxAttempts
        self.maxDuration = maxDuration
    }
    
    public func execute<T: FirestoreRetryable>(_ operation: T) async throws -> T.Output {
        var attempt = 0
        let startTime = Date()
        
        while true {
            do {
                return try await operation.execute()
            } catch {
                attempt += 1
                
                let context = FirestoreRetryContext(
                    attempt: attempt,
                    error: error,
                    startTime: startTime,
                    strategy: strategy
                )
                
                guard attempt < maxAttempts else {
                    throw FirestoreError.maxAttemptsReached
                }
                
                if let maxDuration = maxDuration,
                   context.elapsedTime >= maxDuration {
                    throw error
                }
                
                let delay = calculateDelay(for: context)
                if let delay = delay {
                    try await Task.sleep(for: delay)
                } else {
                    throw error
                }
            }
        }
    }

    private func calculateDelay(for context: FirestoreRetryContext) -> Duration? {
        switch strategy {
        case .exponentialBackoff(let initial, let maximum, let multiplier, let jitter):
            let base = Double(initial.nanoseconds) * pow(multiplier, Double(context.attempt - 1))
            let jitterRange = base * jitter
            let jitterAmount = Double.random(in: -jitterRange...jitterRange)
            let delayNanos = Int64(min(base + jitterAmount, Double(maximum.nanoseconds)))
            return .nanoseconds(delayNanos)

        case .linearBackoff(let interval, let maximum):
            let delayNanos = interval.nanoseconds * Int64(context.attempt)
            return .nanoseconds(min(delayNanos, maximum.nanoseconds))

        case .custom(let calculator):
            return calculator(context.attempt)

        case .none:
            return nil
        }
    }
}
