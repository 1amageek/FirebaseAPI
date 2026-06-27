import FirestoreRuntimeConfig
import Logging

extension FirestoreLogLevel {
    func toLoggerLevel() -> Logger.Level {
        switch self {
        case .trace: return .trace
        case .debug: return .debug
        case .info: return .info
        case .notice: return .notice
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        }
    }
}
