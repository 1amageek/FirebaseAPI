//
//  String.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/09.
//

import Foundation

extension String {

    var normalized: String {
        self
            .split(separator: "/")
            .filter({ !$0.isEmpty })
            .joined(separator: "/")
    }
}
