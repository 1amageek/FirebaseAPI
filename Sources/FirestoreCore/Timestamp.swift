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
    public let seconds: Int64

    /// The number of nanoseconds within the second. Must be from 0 to 999,999,999 inclusive.
    public let nanos: Int32

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
        var seconds = floor(date.timeIntervalSince1970)
        var nanos = ((date.timeIntervalSince1970 - seconds) * 1_000_000_000).rounded()
        if nanos >= 1_000_000_000 {
            seconds += 1
            nanos = 0
        }
        self.init(seconds: Int64(seconds), nanos: Int32(nanos))
    }

    /**
     Returns a `Timestamp` instance that represents the current time.

     - Returns: A `Timestamp` instance that represents the current time.
     */
    public static func now() -> Timestamp {
        Timestamp(Date())
    }
}

extension Timestamp {

    public init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        minute: Int? = nil,
        second: Int? = nil,
        nanosecond: Int? = nil,
        timeZone: TimeZone = .autoupdatingCurrent
    ) throws {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = timeZone
        let dateComponents = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        guard let date = calendar.date(from: dateComponents) else {
            throw FirestoreError.invalidFieldValue("Timestamp date components must form a valid date.")
        }
        let resolved = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        guard resolved.year == year,
              resolved.month == month,
              resolved.day == day,
              resolved.hour == (hour ?? 0),
              resolved.minute == (minute ?? 0),
              resolved.second == (second ?? 0) else {
            throw FirestoreError.invalidFieldValue("Timestamp date components must form a valid date.")
        }
        let nanosecond = nanosecond ?? 0
        guard (0...999_999_999).contains(nanosecond) else {
            throw FirestoreError.invalidFieldValue("Timestamp nanosecond must be between 0 and 999,999,999.")
        }
        self.init(seconds: Int64(date.timeIntervalSince1970), nanos: Int32(nanosecond))
    }
}

extension Date {
    /**
     Initializes a `Date` instance based on a `Timestamp` object.

     - Parameter timestamp: The `Timestamp` instance to initialize the `Date` object from.
     */
    public init(timestamp: Timestamp) {
        self.init(
            timeIntervalSince1970: TimeInterval(timestamp.seconds)
                + TimeInterval(timestamp.nanos) / 1_000_000_000
        )
    }
}
