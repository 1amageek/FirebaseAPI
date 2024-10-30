//
//  Query+KeyedEncodingContainer.swift
//  FirebaseAPI
//
//  Created by Norikazu Muramoto on 2024/10/30.
//

import Foundation

extension KeyedEncodingContainer where Key : CodingKey {
    
    fileprivate mutating func encode(_ value: Any, forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value as? Bool {
            try encode(value, forKey: key)
        } else if let value = value as? String {
            try encode(value, forKey: key)
        } else if let value = value as? Double {
            try encode(value, forKey: key)
        } else if let value = value as? Float {
            try encode(value, forKey: key)
        } else if let value = value as? Int {
            try encode(value, forKey: key)
        } else if let value = value as? Int8 {
            try encode(value, forKey: key)
        } else if let value = value as? Int16 {
            try encode(value, forKey: key)
        } else if let value = value as? Int32 {
            try encode(value, forKey: key)
        } else if let value = value as? Int64 {
            try encode(value, forKey: key)
        } else if let value = value as? UInt {
            try encode(value, forKey: key)
        } else if let value = value as? UInt8 {
            try encode(value, forKey: key)
        } else if let value = value as? UInt16 {
            try encode(value, forKey: key)
        } else if let value = value as? UInt32 {
            try encode(value, forKey: key)
        } else if let value = value as? UInt64 {
            try encode(value, forKey: key)
        }
    }
    
    fileprivate mutating func encode(_ value: [Any], forKey key: KeyedEncodingContainer<K>.Key) throws {
        if let value = value as? [Bool] {
            try encode(value, forKey: key)
        } else if let value = value as? [String] {
            try encode(value, forKey: key)
        } else if let value = value as? [Double] {
            try encode(value, forKey: key)
        } else if let value = value as? [Float] {
            try encode(value, forKey: key)
        } else if let value = value as? [Int] {
            try encode(value, forKey: key)
        } else if let value = value as? [Int8] {
            try encode(value, forKey: key)
        } else if let value = value as? [Int16] {
            try encode(value, forKey: key)
        } else if let value = value as? [Int32] {
            try encode(value, forKey: key)
        } else if let value = value as? [Int64] {
            try encode(value, forKey: key)
        } else if let value = value as? [UInt] {
            try encode(value, forKey: key)
        } else if let value = value as? [UInt8] {
            try encode(value, forKey: key)
        } else if let value = value as? [UInt16] {
            try encode(value, forKey: key)
        } else if let value = value as? [UInt32] {
            try encode(value, forKey: key)
        } else if let value = value as? [UInt64] {
            try encode(value, forKey: key)
        }
    }
}
