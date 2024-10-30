//
//  FirestoreSetting.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import GRPC
import NIO

public struct FirestoreSettings {
    public var host: String
    public var port: Int
    public var usesSSL: Bool
    public var timeout: TimeAmount
    public var cacheEnabled: Bool
    public var persistenceEnabled: Bool
    public var maxConcurrentLimits: Int
    public var retryStrategy: FirestoreRetryStrategy
    public var logLevel: FirestoreLogLevel
    
    public init(
        host: String = "firestore.googleapis.com",
        port: Int = 443,
        usesSSL: Bool = true,
        timeout: TimeAmount = .seconds(30),
        cacheEnabled: Bool = true,
        persistenceEnabled: Bool = false,
        maxConcurrentLimits: Int = 100,
        retryStrategy: FirestoreRetryStrategy = .exponentialBackoff(),
        logLevel: FirestoreLogLevel = .info
    ) {
        self.host = host
        self.port = port
        self.usesSSL = usesSSL
        self.timeout = timeout
        self.cacheEnabled = cacheEnabled
        self.persistenceEnabled = persistenceEnabled
        self.maxConcurrentLimits = maxConcurrentLimits
        self.retryStrategy = retryStrategy
        self.logLevel = logLevel
    }
}

public enum FirestoreRetryStrategy {
    case exponentialBackoff(
        initial: TimeAmount = .milliseconds(100),
        maximum: TimeAmount = .seconds(60),
        multiplier: Double = 1.5,
        jitter: Double = 0.1
    )
    case linearBackoff(
        interval: TimeAmount = .seconds(1),
        maximum: TimeAmount = .seconds(60)
    )
    case custom((Int) -> TimeAmount?)
    case none
}

public enum FirestoreLogLevel: Int {
    case trace = 0
    case debug = 1
    case info = 2
    case notice = 3
    case warning = 4
    case error = 5
    case critical = 6
}
