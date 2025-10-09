//
//  ExponentialBackoff.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation


/**
 Represents an error that occurs when the maximum number of retries is exceeded during exponential backoff.

 exceededMaxRetries: The maximum number of retries has been exceeded.
 */
enum ExponentialBackoffError: Error {
    case exceededMaxRetries
}
/**
 A utility class that implements exponential backoff for retrying operations with delays.

 The exponential backoff algorithm increases the delay between retries exponentially based on a configurable backoff factor and limits the maximum delay and maximum number of retries.

 Usage:

 Create an instance of ExponentialBackoff with desired parameters.
 Call backoffAndWait method in an async context to perform an operation with exponential backoff.
 Handle any errors thrown by the operation.
 Example:
 let backoff = ExponentialBackoff()
 do {
 try await backoff.backoffAndWait {
 // Perform an operation that may fail and should be retried with exponential backoff
 }
 } catch {
 // Handle the error, such as exceeded max retries
 }
 Parameters:

 initialDelay: The initial delay in seconds before the first retry. Default is 0.25 second.
 backoffFactor: The multiplier applied to the current delay to calculate the next delay. Default is 1.5.
 maxDelay: The maximum delay in seconds between retries. Default is 60.0 seconds.
 jitterFactor: The factor to introduce jitter in the delays. Jitter helps distribute the retries over a range of time to avoid potential congestion. Default is 1.0 (no jitter).
 maxAttempts: The maximum number of retry attempts. Default is 5.
 Note: This class uses the DocC format for documenting Swift code.
 */

class ExponentialBackoff {
    var initialDelay: TimeInterval
    var backoffFactor: Double
    var maxDelay: TimeInterval
    var jitterFactor: Double
    var retryCount: Int
    var maxAttempts: Int
    var currentBase: TimeInterval

    /**
     Initializes an instance of ExponentialBackoff with the specified parameters.

     Parameters:
     initialDelay: The initial delay in seconds before the first retry. Default is 0.25 second.
     backoffFactor: The multiplier applied to the current delay to calculate the next delay. Default is 1.5.
     maxDelay: The maximum delay in seconds between retries. Default is 60.0 seconds.
     jitterFactor: The factor to introduce jitter in the delays. Jitter helps distribute the retries over a range of time to avoid potential congestion. Default is 1.0 (no jitter).
     maxAttempts: The maximum number of retry attempts. Default is 5.
     */
    init(
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
        self.retryCount = 0
        self.currentBase = initialDelay
        self.maxAttempts = maxAttempts
    }

    /**
     Resets the retry count and current base delay to their initial values.
     */
    func reset() {
        self.retryCount = 0
        self.currentBase = initialDelay
    }

    /**
     Indicates whether another retry attempt should be made.

     Returns: true if another retry attempt should be made, false otherwise
     */
    var shouldRetry: Bool {
        retryCount < maxAttempts
    }

    /**
     Performs exponential backoff and waits for the calculated delay.

     - Throws: An `ExponentialBackoffError.exceededMaxRetries` error if the maximum number of retries is exceeded.

     - Note: This method should be called in an `async` context.

     - Example:
     ```swift
     try await backoff.backoffAndWait {
     // Perform an operation that may fail and should be retried with exponential backoff
     }
     ```

     - SeeAlso: `reset`
     */
    func backoffAndWait() async throws {
        if self.retryCount >= maxAttempts {
            throw ExponentialBackoffError.exceededMaxRetries
        }

        let delayWithJitter = self.currentBase + self.jitterDelay()
        self.currentBase *= self.backoffFactor
        self.currentBase = min(self.currentBase, self.maxDelay)
        self.retryCount += 1

        // Wait for the calculated delay.
        try await Task.sleep(nanoseconds: UInt64(delayWithJitter * 1_000_000_000))  // nanoseconds
    }

    private func jitterDelay() -> TimeInterval {
        return (Double.random(in: 0...1) - 0.5) * self.jitterFactor * self.currentBase
    }
}
