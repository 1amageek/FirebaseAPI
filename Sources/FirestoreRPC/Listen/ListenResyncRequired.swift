//
//  ListenResyncRequired.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore

package struct ListenResyncRequired: Error, Equatable, Sendable {
    package let targetID: Int32
    package let expectedCount: Int
    package let actualCount: Int

    package init(
        targetID: Int32,
        expectedCount: Int,
        actualCount: Int
    ) {
        self.targetID = targetID
        self.expectedCount = expectedCount
        self.actualCount = actualCount
    }
}
