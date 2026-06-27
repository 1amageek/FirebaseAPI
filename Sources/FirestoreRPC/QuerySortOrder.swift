//
//  QuerySortOrder.swift
//
//
//  Created on 2026/06/25.
//

import Foundation
import FirestoreCore

package struct QuerySortOrder: Equatable, Sendable {
    package let fieldPath: String
    package let descending: Bool

    package init(fieldPath: String, descending: Bool) {
        self.fieldPath = fieldPath
        self.descending = descending
    }
}
