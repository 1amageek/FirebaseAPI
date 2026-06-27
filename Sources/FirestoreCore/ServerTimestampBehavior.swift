import Foundation

public enum ServerTimestampBehavior: Sendable, Equatable {
    case none
    case estimate
    case previous
}
