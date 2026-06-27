import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

actor FirestoreTCPProxy {
    private let targetHost: String
    private let targetPort: Int
    private var listenFileDescriptor: Int32 = -1
    private var activeConnections: [Int32: ProxyConnection] = [:]

    init(targetHost: String, targetPort: Int) {
        self.targetHost = targetHost
        self.targetPort = targetPort
    }

    func start() throws -> Int {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            throw FirestoreTCPProxyError.socket("Failed to create proxy listener socket.")
        }

        do {
            try Self.configureReusableAddress(descriptor)
            let port = try Self.bindLoopbackListener(descriptor)
            try Self.startListening(descriptor)
            listenFileDescriptor = descriptor

            let targetHost = self.targetHost
            let targetPort = self.targetPort
            Task.detached {
                await Self.runAcceptLoop(
                    listenFileDescriptor: descriptor,
                    targetHost: targetHost,
                    targetPort: targetPort,
                    owner: self
                )
            }

            return port
        } catch {
            Self.closeSocket(descriptor)
            throw error
        }
    }

    func dropActiveConnections() {
        let connections = activeConnections.values
        activeConnections.removeAll()
        for connection in connections {
            Self.closeSocket(connection.clientFileDescriptor)
            Self.closeSocket(connection.upstreamFileDescriptor)
        }
    }

    func stop() {
        if listenFileDescriptor >= 0 {
            Self.closeSocket(listenFileDescriptor)
            listenFileDescriptor = -1
        }
        dropActiveConnections()
    }

    private func register(
        clientFileDescriptor: Int32,
        upstreamFileDescriptor: Int32
    ) {
        activeConnections[clientFileDescriptor] = ProxyConnection(
            clientFileDescriptor: clientFileDescriptor,
            upstreamFileDescriptor: upstreamFileDescriptor
        )
    }

    private func closeConnection(clientFileDescriptor: Int32) {
        guard let connection = activeConnections.removeValue(forKey: clientFileDescriptor) else {
            return
        }
        Self.closeSocket(connection.clientFileDescriptor)
        Self.closeSocket(connection.upstreamFileDescriptor)
    }

    private static func runAcceptLoop(
        listenFileDescriptor: Int32,
        targetHost: String,
        targetPort: Int,
        owner: FirestoreTCPProxy
    ) async {
        while true {
            let clientFileDescriptor = accept(listenFileDescriptor, nil, nil)
            if clientFileDescriptor < 0 {
                return
            }

            do {
                let upstreamFileDescriptor = try connectToTarget(host: targetHost, port: targetPort)
                await owner.register(
                    clientFileDescriptor: clientFileDescriptor,
                    upstreamFileDescriptor: upstreamFileDescriptor
                )
                startForwarding(
                    clientFileDescriptor: clientFileDescriptor,
                    upstreamFileDescriptor: upstreamFileDescriptor,
                    owner: owner
                )
            } catch {
                closeSocket(clientFileDescriptor)
            }
        }
    }

    private static func startForwarding(
        clientFileDescriptor: Int32,
        upstreamFileDescriptor: Int32,
        owner: FirestoreTCPProxy
    ) {
        Task.detached {
            copyBytes(from: clientFileDescriptor, to: upstreamFileDescriptor)
            await owner.closeConnection(clientFileDescriptor: clientFileDescriptor)
        }

        Task.detached {
            copyBytes(from: upstreamFileDescriptor, to: clientFileDescriptor)
            await owner.closeConnection(clientFileDescriptor: clientFileDescriptor)
        }
    }

    private static func copyBytes(from source: Int32, to destination: Int32) {
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        while true {
            let bytesRead = buffer.withUnsafeMutableBufferPointer { pointer in
                read(source, pointer.baseAddress, pointer.count)
            }

            if bytesRead <= 0 {
                return
            }

            var bytesWritten = 0
            while bytesWritten < bytesRead {
                let result = buffer.withUnsafeBufferPointer { pointer in
                    write(
                        destination,
                        pointer.baseAddress?.advanced(by: bytesWritten),
                        bytesRead - bytesWritten
                    )
                }
                if result <= 0 {
                    return
                }
                bytesWritten += result
            }
        }
    }

    private static func configureReusableAddress(_ descriptor: Int32) throws {
        var enabled: Int32 = 1
        let result = setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_REUSEADDR,
            &enabled,
            socklen_t(MemoryLayout.size(ofValue: enabled))
        )
        guard result == 0 else {
            throw FirestoreTCPProxyError.socket("Failed to configure proxy listener socket.")
        }
    }

    private static func bindLoopbackListener(_ descriptor: Int32) throws -> Int {
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(0).bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { reboundPointer in
                bind(descriptor, reboundPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            throw FirestoreTCPProxyError.socket("Failed to bind proxy listener socket.")
        }

        var boundAddress = sockaddr_in()
        var boundAddressLength = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &boundAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { reboundPointer in
                getsockname(descriptor, reboundPointer, &boundAddressLength)
            }
        }
        guard nameResult == 0 else {
            throw FirestoreTCPProxyError.socket("Failed to read proxy listener port.")
        }

        return Int(in_port_t(bigEndian: boundAddress.sin_port))
    }

    private static func startListening(_ descriptor: Int32) throws {
        guard listen(descriptor, SOMAXCONN) == 0 else {
            throw FirestoreTCPProxyError.socket("Failed to start proxy listener socket.")
        }
    }

    private static func connectToTarget(host: String, port: Int) throws -> Int32 {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, String(port), &hints, &result)
        guard status == 0, let result else {
            throw FirestoreTCPProxyError.socket("Failed to resolve proxy target.")
        }
        defer {
            freeaddrinfo(result)
        }

        var current: UnsafeMutablePointer<addrinfo>? = result
        while let candidate = current {
            let descriptor = socket(
                candidate.pointee.ai_family,
                candidate.pointee.ai_socktype,
                candidate.pointee.ai_protocol
            )
            if descriptor >= 0 {
                let connected = connect(
                    descriptor,
                    candidate.pointee.ai_addr,
                    candidate.pointee.ai_addrlen
                ) == 0
                if connected {
                    return descriptor
                }
                closeSocket(descriptor)
            }
            current = candidate.pointee.ai_next
        }

        throw FirestoreTCPProxyError.socket("Failed to connect proxy target.")
    }

    private static func closeSocket(_ descriptor: Int32) {
        guard descriptor >= 0 else {
            return
        }
        configureResetOnClose(descriptor)
        _ = shutdown(descriptor, SHUT_RDWR)
        _ = close(descriptor)
    }

    private static func configureResetOnClose(_ descriptor: Int32) {
        var lingerOption = linger(l_onoff: 1, l_linger: 0)
        _ = setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_LINGER,
            &lingerOption,
            socklen_t(MemoryLayout.size(ofValue: lingerOption))
        )
    }
}

private struct ProxyConnection: Sendable {
    let clientFileDescriptor: Int32
    let upstreamFileDescriptor: Int32
}

private enum FirestoreTCPProxyError: Error, CustomStringConvertible {
    case socket(String)

    var description: String {
        switch self {
        case .socket(let message):
            return message
        }
    }
}
