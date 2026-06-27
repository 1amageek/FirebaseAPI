//
//  IDGenerator.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation

struct IDGenerator {
    static let length: Int = 20
    static let availableCharacters: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    static func generate(characters: String = IDGenerator.availableCharacters, length: Int = IDGenerator.length) -> String {
        var autoID: String = ""
        (0..<length).forEach { _ in
            let random = Int.random(in: 0..<characters.count)
            let startIndex = characters.startIndex
            let from = characters.index(startIndex, offsetBy: random)
            let to = characters.index(startIndex, offsetBy: random + 1)
            let character = String(characters[from..<to])
            autoID.append(character)
        }
        return autoID
    }
}
