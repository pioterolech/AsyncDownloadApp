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

// MARK: - Tests

@Suite("DownloadManager")
struct DownloadManagerTests {

    let storage = DownloadStorageProtocolMock()
    let streamer = NetworkBytesFetcherProtocolMock()
    let url = URL(string: "https://example.com/file.zip")!

    @Test("add transitions through queued → downloading → completed")
    func addCompletesSuccessfully() async throws {
        storage.createTempFileReturnValue = URL(filePath: "/tmp/mock")
        storage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        streamer.fetchHandler = { _, _, onProgress in
            await onProgress(512, 1024)
            await onProgress(1024, 1024)
        }

        let manager = DownloadManager(storage: storage, streamer: streamer)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.queued, .downloading, .downloading, .downloading, .completed])
        #expect(emissions.last?.first?.fileURL == URL(filePath: "/docs/mock.zip"))
        #expect(emissions.last?.first?.progress == 1.0)
    }

    @Test("cancel transitions download to cancelled state")
    func cancelStopsDownload() async throws {
        storage.createTempFileReturnValue = URL(filePath: "/tmp/mock")
        streamer.fetchHandler = { _, _, _ in
            try await Task.sleep(for: .seconds(10))
        }

        let manager = DownloadManager(storage: storage, streamer: streamer)
        await manager.add(url: url)

        let downloading = await manager.downloadStream.collect { $0.first?.state == .downloading }
        let id = try #require(downloading.last?.first?.id)

        await manager.cancel(id: id)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .cancelled }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.cancelled])
        #expect(storage.deleteTempFileCallCount == 1)
    }

    @Test("remove eliminates download from stream")
    func removeDeletesDownload() async throws {
        storage.createTempFileReturnValue = URL(filePath: "/tmp/mock")
        storage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        streamer.fetchHandler = { _, _, onProgress in
            await onProgress(1024, 1024)
        }

        let manager = DownloadManager(storage: storage, streamer: streamer)
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
        storage.createTempFileReturnValue = URL(filePath: "/tmp/mock")
        streamer.fetchThrowableError = FetchError()

        let manager = DownloadManager(storage: storage, streamer: streamer)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .failed }
        let states = emissions.compactMap { $0.first?.state }

        #expect(states == [.queued, .downloading, .failed])
        #expect(storage.deleteTempFileCallCount == 1)
    }

    @Test("progress is reported during fetch")
    func progressIsUpdated() async throws {
        storage.createTempFileReturnValue = URL(filePath: "/tmp/mock")
        storage.moveToDocumentsReturnValue = URL(filePath: "/docs/mock.zip")
        streamer.fetchHandler = { _, _, onProgress in
            await onProgress(256, 1024)
            await onProgress(512, 1024)
            await onProgress(1024, 1024)
        }

        let manager = DownloadManager(storage: storage, streamer: streamer)
        await manager.add(url: url)

        let emissions = await manager.downloadStream.collect { $0.first?.state == .completed }
        let progressValues = emissions.compactMap { $0.first?.progress }

        #expect(progressValues == [0.0, 0.0, 0.25, 0.5, 1.0, 1.0])
    }
}
