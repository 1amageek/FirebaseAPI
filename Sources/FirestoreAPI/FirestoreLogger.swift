//
//  FirestoreLogger.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import Logging

public final class FirestoreLogger {
    private var logger: Logger
    private var metadata: Logger.Metadata
    
    public init(label: String, logLevel: FirestoreLogLevel = .info) {
        self.logger = Logger(label: label)
        self.logger.logLevel = logLevel.toLoggerLevel()
        self.metadata = [:]
    }
    
    public func setLogLevel(_ level: FirestoreLogLevel) {
        logger.logLevel = level.toLoggerLevel()
    }
    
    public func setMetadata(_ metadata: Logger.Metadata) {
        self.metadata = metadata
        logger[metadataKey: "firestore"] = .dictionary(metadata)
    }
    
    public func updateMetadata(_ metadata: Logger.Metadata) {
        self.metadata.merge(metadata) { _, new in new }
        logger[metadataKey: "firestore"] = .dictionary(self.metadata)
    }
    
    public func trace(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.trace, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func debug(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.debug, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.info, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func notice(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.notice, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.warning, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.error, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String, metadata: Logger.Metadata? = nil, file: String = #file, function: String = #function, line: UInt = #line) {
        log(.critical, message, metadata: metadata, file: file, function: function, line: line)
    }
    
    private func log(_ level: Logger.Level, _ message: String, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        if let metadata = metadata {
            var combinedMetadata = self.metadata
            combinedMetadata.merge(metadata) { _, new in new }
            logger[metadataKey: "firestore"] = .dictionary(combinedMetadata)
        }
        logger.log(
            level: level,
            "\(message)",
            metadata: metadata,
            source: nil,
            file: file,
            function: function,
            line: line
        )
    }
}

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
