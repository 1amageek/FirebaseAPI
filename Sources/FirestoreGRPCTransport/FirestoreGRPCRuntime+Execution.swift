import Foundation
import GRPCCore

extension FirestoreGRPCRuntime {
    internal var callOptions: CallOptions {
        var options = CallOptions.defaults
        options.timeout = settings.timeout
        return options
    }

    internal var retryMaxDuration: TimeInterval {
        let (seconds, attoseconds) = settings.timeout.components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1_000_000_000_000_000_000
    }

    internal var finiteRPCExecutor: FirestoreRPCExecutor {
        FirestoreRPCExecutor(
            retryStrategy: settings.retryStrategy,
            maxAttempts: settings.maxRetryAttempts,
            maxDuration: retryMaxDuration
        )
    }
}
