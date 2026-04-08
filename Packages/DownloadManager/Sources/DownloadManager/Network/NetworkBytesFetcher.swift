import Foundation

// sourcery: AutoMockable
public protocol NetworkBytesFetcherProtocol {
    func fetch(
        from url: URL,
        into fileURL: URL,
        onProgress: @escaping (Int64, Int64) async -> Void
    ) async throws
}

final class NetworkBytesFetcher: NetworkBytesFetcherProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(
        from url: URL,
        into fileURL: URL,
        onProgress: @escaping (Int64, Int64) async -> Void
    ) async throws {
        let fileHandle = try FileHandle(forWritingTo: fileURL)
        defer { try? fileHandle.close() }

        let (asyncBytes, response) = try await session.bytes(from: url)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw DownloadError.unknown
        }

        let totalBytes = http.expectedContentLength
        var buffer = Data(capacity: 65_536)
        var receivedBytes: Int64 = 0

        for try await byte in asyncBytes {
            buffer.append(byte)
            receivedBytes += 1

            if buffer.count >= 65_536 {
                try fileHandle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                if totalBytes > 0 {
                    await onProgress(receivedBytes, totalBytes)
                }
            }
        }

        if !buffer.isEmpty {
            try fileHandle.write(contentsOf: buffer)
        }
        if totalBytes > 0 {
            await onProgress(receivedBytes, totalBytes)
        }
    }
}
