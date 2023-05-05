//
//  FirestoreKey.swift
//  
//
//  Created by Norikazu Muramoto on 2023/05/04.
//

import Foundation

struct FirestoreKey: CodingKey {
    
    var stringValue: String

    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        stringValue = "[\(index)]"
        intValue = index
    }

    var description: String {
        return "\(stringValue)"
    }
}

class CodingKeyManager {

    var codingPath: [FirestoreKey] = []

    var message: String { codingPath.lazy.map({ $0.stringValue }).joined(separator: ".") }

    init() { }
}

