//
//  FirestoreSetting.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation
import FirestoreCore

public struct FirestoreSettings: Sendable {
    public var host: String
    public var port: Int
    public var usesSSL: Bool
    public var timeout: Duration
    public var maxRetryAttempts: Int
    public var retryStrategy: FirestoreRetryStrategy
    public var logLevel: FirestoreLogLevel
    public var authenticationMode: FirestoreAuthenticationMode
    package var allowsDisabledAuthentication: Bool

    public init(
        host: String = "firestore.googleapis.com",
        port: Int = 443,
        usesSSL: Bool = true,
        timeout: Duration = .seconds(30),
        maxRetryAttempts: Int = 5,
        retryStrategy: FirestoreRetryStrategy = .exponentialBackoff(),
        logLevel: FirestoreLogLevel = .info,
        authenticationMode: FirestoreAuthenticationMode = .required
    ) {
        self.host = host
        self.port = port
        self.usesSSL = usesSSL
        self.timeout = timeout
        self.maxRetryAttempts = maxRetryAttempts
        self.retryStrategy = retryStrategy
        self.logLevel = logLevel
        self.authenticationMode = authenticationMode
        self.allowsDisabledAuthentication = false
    }

    public static func emulator(
        host: String = "127.0.0.1",
        port: Int = 8080,
        timeout: Duration = .seconds(30),
        maxRetryAttempts: Int = 5,
        retryStrategy: FirestoreRetryStrategy = .exponentialBackoff(),
        logLevel: FirestoreLogLevel = .info
    ) -> FirestoreSettings {
        var settings = FirestoreSettings(
            host: host,
            port: port,
            usesSSL: false,
            timeout: timeout,
            maxRetryAttempts: maxRetryAttempts,
            retryStrategy: retryStrategy,
            logLevel: logLevel,
            authenticationMode: .disabled
        )
        settings.allowsDisabledAuthentication = true
        return settings
    }

    package func validateAuthenticationBoundary(hasAccessTokenProvider: Bool) throws {
        switch authenticationMode {
        case .required:
            guard hasAccessTokenProvider else {
                throw FirestoreError.invalidConfiguration(
                    "Firestore authentication is required. Use service account credentials, application default credentials, a custom access token provider, or emulator settings."
                )
            }
        case .disabled:
            guard allowsDisabledAuthentication else {
                throw FirestoreError.invalidConfiguration(
                    "Disabled Firestore authentication is only supported through emulator settings."
                )
            }
            guard !usesSSL else {
                throw FirestoreError.invalidConfiguration(
                    "Disabled Firestore authentication requires plaintext emulator settings."
                )
            }
            guard !host.localizedCaseInsensitiveContains("googleapis.com") else {
                throw FirestoreError.invalidConfiguration(
                    "Disabled Firestore authentication cannot target Google APIs hosts."
                )
            }
        }
    }
}

public enum FirestoreRetryStrategy: Sendable {
    case exponentialBackoff(
        initial: Duration = .milliseconds(100),
        maximum: Duration = .seconds(60),
        multiplier: Double = 1.5,
        jitter: Double = 0.1
    )
    case linearBackoff(
        interval: Duration = .seconds(1),
        maximum: Duration = .seconds(60)
    )
    case custom(@Sendable (Int) -> Duration?)
    case none
}

public enum FirestoreLogLevel: Int, Sendable {
    case trace = 0
    case debug = 1
    case info = 2
    case notice = 3
    case warning = 4
    case error = 5
    case critical = 6
}
