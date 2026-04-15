import Testing
import Foundation
@testable import DownloadManager

// MARK: - Helpers

extension AsyncStream where Element == [Download] {
    func collect(until predicate: (Element) -> Bool) async -> [[Download]] {
        var results: [[Download]] = []
        for await element in self {
            results.append(element)
            if predicate(element) { break }
        }
        return results
    }
}

// MARK: - Mock

final class DownloadTaskMock: DownloadTaskProtocol, @unchecked Sendable {
    var fetchHandler: ((URL) -> AsyncThrowingStream<DownloadTaskEvent, Error>)?

    func fetch(from url: URL) async -> AsyncThrowingStream<DownloadTaskEvent, Error> {
        fetchHandler?(url) ?? AsyncThrowingStream { $0.finish() }
    }
}

// MARK: - Tests

@Suite("DownloadManager")
struct DownloadManagerTests {

    let storage = FileStorageProtocolMock()
    let downloadTask = DownloadTaskMock()
    let url = URL(string: "https://example.com/file.zip")!

    @Test("add transitions through queued → downloading → completed")
    func addCompletesSuccessfully() async throws {
        let tempURL = URL(filePath: "/tmp/mock")
        let destURL = URL(filePath: "/docs/mock.zip")
        storage.moveToDocumentsReturnValue = destURL
        downloadTask.fetchHandler = { _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.progress(512, 1024))
                continuation.yield(.progress(1024, 1024))
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }

        let manager = DownloadManager(storage: storage, downloadTask: downloadTask)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.queued, .downloading, .downloading, .downloading, .completed])
        #expect(emissions.last?.first?.fileURL == destURL)
        #expect(emissions.last?.first?.progress == 1.0)
    }

    @Test("cancel transitions download to cancelled state")
    func cancelStopsDownload() async throws {
        downloadTask.fetchHandler = { _ in
            AsyncThrowingStream { _ in }
        }

        let manager = DownloadManager(storage: storage, downloadTask: downloadTask)
        await manager.add(url: url)

        let downloading = await manager.downloadStream.collect { $0.first?.state == .downloading }
        let id = try #require(downloading.last?.first?.id)

        await manager.cancel(id: id)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .cancelled }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.cancelled])
    }

    @Test("remove eliminates download from stream")
    func removeDeletesDownload() async throws {
        let tempURL = URL(filePath: "/tmp/mock")
        storage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }

        let manager = DownloadManager(storage: storage, downloadTask: downloadTask)
        await manager.add(url: url)

        let completed = await manager.downloadStream.collect { $0.first?.state == .completed }
        let id = try #require(completed.last?.first?.id)

        await manager.remove(id: id)

        let emissions = await manager.downloadStream.collect { $0.isEmpty }
        #expect(emissions.last?.isEmpty == true)
    }

    @Test("failed fetch transitions download to failed state")
    func fetchErrorTransitionsToFailed() async throws {
        struct FetchError: Error {}
        downloadTask.fetchHandler = { _ in
            AsyncThrowingStream { continuation in
                continuation.finish(throwing: FetchError())
            }
        }

        let manager = DownloadManager(storage: storage, downloadTask: downloadTask)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .failed }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.queued, .downloading, .failed])
    }

    @Test("progress is reported during fetch")
    func progressIsUpdated() async throws {
        let tempURL = URL(filePath: "/tmp/mock")
        storage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        downloadTask.fetchHandler = { _ in
            AsyncThrowingStream { continuation in
                continuation.yield(.progress(256, 1024))
                continuation.yield(.progress(512, 1024))
                continuation.yield(.progress(1024, 1024))
                continuation.yield(.completed(tempURL))
                continuation.finish()
            }
        }

        let manager = DownloadManager(storage: storage, downloadTask: downloadTask)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }
        let progressValues = emissions.compactMap { $0.first?.progress }

        #expect(progressValues == [0.0, 0.0, 0.25, 0.5, 1.0, 1.0])
    }
}
