//
//  Timestamp.swift
//  
//
//  Created by Norikazu Muramoto on 2023/04/11.
//

import Foundation

/**
 A struct that represents a timestamp.

 Use a `Timestamp` instance to represent a point in time, with second and nanosecond precision.

 A `Timestamp` instance requires a number of seconds since the Unix epoch (1970-01-01T00:00:00Z) and a number of nanoseconds to represent a time.

 You can create a `Timestamp` instance using the `init(seconds:nanos:)` initializer, passing in the number of seconds and nanoseconds.

 You can also create a `Timestamp` instance that represents the current time using the `now()` static method.

 `Timestamp` conforms to `Codable` and `Equatable`.

 */
public struct Timestamp: Codable, Equatable, Sendable {

    /// The number of seconds since the Unix epoch (1970-01-01T00:00:00Z).
    public var seconds: Int64

    /// The number of nanoseconds within the second. Must be from 0 to 999,999,999 inclusive.
    public var nanos: Int32

    /**
     Initializes a new `Timestamp` instance with the specified number of seconds and nanoseconds.

     - Parameters:
     - seconds: The number of seconds since the Unix epoch (1970-01-01T00:00:00Z).
     - nanos: The number of nanoseconds within the second.
     */
    public init(seconds: Int64, nanos: Int32) {
        self.seconds = seconds
        self.nanos = nanos
    }

    /**
     Initializes a new `Timestamp` instance with the specified `Date` value.

     - Parameters:
     - date: The `Date` value to initialize the `Timestamp` instance with.
     */
    public init(_ date: Date) {
        self.init(seconds: Int64(date.timeIntervalSince1970), nanos: 0)
    }

    /**
     Returns a `Timestamp` instance that represents the current time.

     - Returns: A `Timestamp` instance that represents the current time.
     */
    public static func now() -> Timestamp {
        let date = Date()
        return Timestamp(seconds: Int64(date.timeIntervalSince1970), nanos: 0)
    }
}

extension Timestamp {

    public init(year: Int, month: Int, day: Int, hour: Int? = nil, minute: Int? = nil, second: Int? = nil, nanosecond: Int? = nil, timeZone: TimeZone = .autoupdatingCurrent) {
        let calendar = Calendar(identifier: .iso8601)
        let dateComponents = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, day: day, hour: hour, minute: month, second: second)
        let date = calendar.date(from: dateComponents)!
        let nanosecond = nanosecond ?? 0
        self.init(seconds: Int64(date.timeIntervalSince1970), nanos: Int32(nanosecond))
    }
}

extension Date {
    /**
     Initializes a `Date` instance based on a `Timestamp` object.

     - Parameter timestamp: The `Timestamp` instance to initialize the `Date` object from.
     */
    public init(timestamp: Timestamp) {
        self.init(timeIntervalSince1970: TimeInterval(timestamp.seconds) + TimeInterval(timestamp.nanos) / 1_000_000)
    }
}
