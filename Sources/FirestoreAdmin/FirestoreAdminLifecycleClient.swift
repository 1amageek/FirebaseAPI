import Foundation
import FirestoreRuntimeConfig

public protocol FirestoreAdminLifecycleClient: Sendable {
    func setLogLevel(_ level: FirestoreLogLevel)
    func shutdown() async
}
