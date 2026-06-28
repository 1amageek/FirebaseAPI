import Foundation

public enum FirestoreAuthenticationMode: Equatable, Sendable {
    case required
    case hostManaged
    case disabled
}
