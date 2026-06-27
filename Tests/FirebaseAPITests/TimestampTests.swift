import Foundation
import Testing
@testable import FirestoreAPI

@Suite("Timestamp Tests")
struct TimestampTests {
    @Test("Timestamp component initializer preserves valid nanoseconds")
    func testTimestampComponentInitializerPreservesValidNanoseconds() throws {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let timestamp = try Timestamp(
            year: 2024,
            month: 2,
            day: 29,
            hour: 12,
            minute: 30,
            second: 45,
            nanosecond: 123_456_789,
            timeZone: timeZone
        )

        #expect(timestamp.nanos == 123_456_789)
        #expect(Date(timestamp: timestamp).timeIntervalSince1970 > 0)
    }

    @Test("Timestamp component initializer rejects invalid components")
    func testTimestampComponentInitializerRejectsInvalidComponents() throws {
        let timeZone = try #require(TimeZone(secondsFromGMT: 0))
        #expect(throws: FirestoreError.self) {
            _ = try Timestamp(
                year: 2023,
                month: 2,
                day: 29,
                timeZone: timeZone
            )
        }
        #expect(throws: FirestoreError.self) {
            _ = try Timestamp(
                year: 2024,
                month: 1,
                day: 1,
                nanosecond: 1_000_000_000,
                timeZone: timeZone
            )
        }
    }
}
