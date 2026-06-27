import Foundation

public struct TransactionOptions {
    package var maxAttempts: Int
    package var readOnly: Bool
    package var readTime: Timestamp?

    public init(maxAttempts: Int = 5, readOnly: Bool = false, readTime: Timestamp? = nil) {
        self.maxAttempts = maxAttempts
        self.readOnly = readOnly
        self.readTime = readTime
    }
}
