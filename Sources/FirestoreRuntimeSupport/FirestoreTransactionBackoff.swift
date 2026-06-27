import Foundation
import FirestoreCore

package final class FirestoreTransactionBackoff {
    private let initialDelay: TimeInterval
    private let backoffFactor: Double
    private let maxDelay: TimeInterval
    private let jitterFactor: Double
    private let maxAttempts: Int
    private var currentBase: TimeInterval

    package private(set) var retryCount: Int

    package init(
        initialDelay: TimeInterval = 0.25,
        backoffFactor: Double = 1.5,
        maxDelay: TimeInterval = 60.0,
        jitterFactor: Double = 1.0,
        maxAttempts: Int = 5
    ) {
        self.initialDelay = initialDelay
        self.backoffFactor = backoffFactor
        self.maxDelay = maxDelay
        self.jitterFactor = jitterFactor
        self.maxAttempts = maxAttempts
        self.currentBase = initialDelay
        self.retryCount = 0
    }

    package var shouldRetry: Bool {
        retryCount < maxAttempts
    }

    package func reset() {
        retryCount = 0
        currentBase = initialDelay
    }

    package func waitBeforeNextAttempt() async throws {
        guard retryCount < maxAttempts else {
            throw FirestoreError.maxAttemptsReached
        }

        let delay = currentBase + jitterDelay()
        currentBase = min(currentBase * backoffFactor, maxDelay)
        retryCount += 1

        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    private func jitterDelay() -> TimeInterval {
        (Double.random(in: 0...1) - 0.5) * jitterFactor * currentBase
    }
}
