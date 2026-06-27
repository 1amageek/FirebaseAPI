//
//  FirestoreRetry.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import FirestoreCore

package protocol FirestoreRetryable: Sendable {
    associatedtype Output
    func execute() async throws -> Output
}

package struct FirestoreRetryContext {
    let attempt: Int
    let error: Error
    let startTime: Date
    let strategy: FirestoreRetryStrategy
    
    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

package actor FirestoreRetryHandler {
    private let strategy: FirestoreRetryStrategy
    private let maxAttempts: Int
    private let maxDuration: TimeInterval?
    
    package init(
        strategy: FirestoreRetryStrategy,
        maxAttempts: Int = 5,
        maxDuration: TimeInterval? = nil
    ) {
        self.strategy = strategy
        self.maxAttempts = maxAttempts
        self.maxDuration = maxDuration
    }
    
    package func execute<T: FirestoreRetryable>(_ operation: T) async throws -> T.Output {
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

                guard shouldRetry(error) else {
                    throw error
                }
                
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

    private func shouldRetry(_ error: Error) -> Bool {
        guard let firestoreError = error as? FirestoreError else {
            return false
        }
        return firestoreError.isRetryableRemoteError
    }

    private func calculateDelay(for context: FirestoreRetryContext) -> Duration? {
        strategy.delay(forAttempt: context.attempt)
    }
}

extension FirestoreRetryStrategy {
    package func delay(forAttempt attempt: Int) -> Duration? {
        switch self {
        case .exponentialBackoff(let initial, let maximum, let multiplier, let jitter):
            let base = Double(Self.nanoseconds(in: initial)) * pow(multiplier, Double(attempt - 1))
            let jitterRange = base * jitter
            let jitterAmount = Double.random(in: -jitterRange...jitterRange)
            let delayNanos = Int64(min(base + jitterAmount, Double(Self.nanoseconds(in: maximum))))
            return .nanoseconds(delayNanos)

        case .linearBackoff(let interval, let maximum):
            let delayNanos = Self.nanoseconds(in: interval) * Int64(attempt)
            return .nanoseconds(min(delayNanos, Self.nanoseconds(in: maximum)))

        case .custom(let calculator):
            return calculator(attempt)

        case .none:
            return nil
        }
    }

    private static func nanoseconds(in duration: Duration) -> Int64 {
        let (seconds, attoseconds) = duration.components
        return (seconds * 1_000_000_000) + (attoseconds / 1_000_000_000)
    }
}
