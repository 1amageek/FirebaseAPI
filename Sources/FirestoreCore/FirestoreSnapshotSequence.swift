import Foundation

public struct FirestoreSnapshotSequence<Snapshot>: AsyncSequence {
    public typealias Element = Snapshot

    public struct AsyncIterator: AsyncIteratorProtocol {
        private let makeStream: () async throws -> AsyncThrowingStream<Snapshot, Error>
        private var iterator: AsyncThrowingStream<Snapshot, Error>.Iterator?

        init(makeStream: @escaping () async throws -> AsyncThrowingStream<Snapshot, Error>) {
            self.makeStream = makeStream
        }

        public mutating func next() async throws -> Snapshot? {
            if iterator == nil {
                let stream = try await makeStream()
                iterator = stream.makeAsyncIterator()
            }
            return try await iterator?.next()
        }
    }

    private let makeStream: () async throws -> AsyncThrowingStream<Snapshot, Error>

    package init(_ makeStream: @escaping () async throws -> AsyncThrowingStream<Snapshot, Error>) {
        self.makeStream = makeStream
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(makeStream: makeStream)
    }
}
