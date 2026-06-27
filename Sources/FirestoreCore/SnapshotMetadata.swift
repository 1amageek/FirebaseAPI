//
//  SnapshotMetadata.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

public struct SnapshotMetadata: Equatable, Sendable {

    public let hasPendingWrites: Bool

    public let isFromCache: Bool

    public init(hasPendingWrites: Bool, isFromCache: Bool) {
        self.hasPendingWrites = hasPendingWrites
        self.isFromCache = isFromCache
    }
}

extension SnapshotMetadata {
    public static let serverSynchronized = SnapshotMetadata(
        hasPendingWrites: false,
        isFromCache: false
    )
}
